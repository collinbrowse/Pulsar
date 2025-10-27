// Edge Function: ingest-activity
// Purpose: Accept multipart file upload (GPX/TCX/FIT), parse, extract stats, store in Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse multipart form data
    const formData = await req.formData()
    const file = formData.get('file') as File
    const activityType = formData.get('activity_type') as string

    if (!file) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate file type
    const fileName = file.name.toLowerCase()
    const fileExtension = fileName.split('.').pop()
    
    if (!['gpx', 'tcx', 'fit'].includes(fileExtension || '')) {
      return new Response(
        JSON.stringify({ error: 'Invalid file type. Must be GPX, TCX, or FIT' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Read file content
    const fileContent = await file.text()
    
    // Parse file (simplified - in production would use proper parsers)
    let stats: any = {}
    
    if (fileExtension === 'gpx') {
      stats = await parseGPX(fileContent)
    } else if (fileExtension === 'tcx') {
      stats = await parseTCX(fileContent)
    } else if (fileExtension === 'fit') {
      // FIT files are binary, would need proper parser
      return new Response(
        JSON.stringify({ error: 'FIT parsing not yet implemented' }),
        { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Upload original file to storage
    const storagePath = `activities/${user.id}/${Date.now()}_${file.name}`
    const { data: uploadData, error: uploadError } = await supabaseClient.storage
      .from('activity-files')
      .upload(storagePath, file)

    if (uploadError) {
      console.error('Storage upload error:', uploadError)
    }

    const fileUrl = uploadData?.path
      ? `${Deno.env.get('SUPABASE_URL')}/storage/v1/object/public/activity-files/${uploadData.path}`
      : null

    // Insert activity into database
    const { data: activity, error: insertError } = await supabaseClient
      .from('activities')
      .insert({
        user_id: user.id,
        activity_type: activityType || 'run',
        name: formData.get('name') || `${activityType || 'Activity'} on ${new Date().toLocaleDateString()}`,
        description: formData.get('description') || null,
        distance_m: stats.distance_m,
        duration_sec: stats.duration_sec,
        elevation_gain_m: stats.elevation_gain_m,
        start_time: stats.start_time,
        end_time: stats.end_time,
        geom: stats.geom, // PostGIS LineString in WKT format
        start_lat: stats.start_lat,
        start_lon: stats.start_lon,
        end_lat: stats.end_lat,
        end_lon: stats.end_lon,
        file_url: fileUrl,
        visibility: formData.get('visibility') || 'public',
      })
      .select()
      .single()

    if (insertError) {
      console.error('Database insert error:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to create activity', details: insertError }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Trigger segment matching (async)
    if (activity && stats.geom) {
      // Call match-segments function
      fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/match-segments`, {
        method: 'POST',
        headers: {
          'Authorization': req.headers.get('Authorization')!,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          activity_id: activity.activity_id,
          activity_geom: stats.geom,
          activity_type: activityType,
        }),
      }).catch(err => console.error('Segment matching failed:', err))
    }

    return new Response(
      JSON.stringify({
        success: true,
        activity_id: activity.activity_id,
        stats: {
          distance_m: stats.distance_m,
          duration_sec: stats.duration_sec,
          elevation_gain_m: stats.elevation_gain_m,
        },
      }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Simplified GPX parser (extract basic stats)
async function parseGPX(content: string): Promise<any> {
  // This is a simplified parser - production would use proper XML parsing
  const trackPoints: any[] = []
  
  // Extract trackpoints (simplified regex - production needs proper XML parser)
  const trkptRegex = /<trkpt lat="([^"]+)" lon="([^"]+)">[\s\S]*?(?:<ele>([^<]+)<\/ele>)?[\s\S]*?(?:<time>([^<]+)<\/time>)?[\s\S]*?<\/trkpt>/g
  
  let match
  while ((match = trkptRegex.exec(content)) !== null) {
    trackPoints.push({
      lat: parseFloat(match[1]),
      lon: parseFloat(match[2]),
      ele: match[3] ? parseFloat(match[3]) : null,
      time: match[4] ? new Date(match[4]) : null,
    })
  }

  if (trackPoints.length === 0) {
    throw new Error('No trackpoints found in GPX file')
  }

  // Calculate distance using Haversine formula
  let totalDistance = 0
  let elevationGain = 0
  
  for (let i = 1; i < trackPoints.length; i++) {
    const prev = trackPoints[i - 1]
    const curr = trackPoints[i]
    
    totalDistance += haversineDistance(prev.lat, prev.lon, curr.lat, curr.lon)
    
    if (prev.ele && curr.ele && curr.ele > prev.ele) {
      elevationGain += (curr.ele - prev.ele)
    }
  }

  // Calculate duration
  const startTime = trackPoints[0].time
  const endTime = trackPoints[trackPoints.length - 1].time
  const durationSec = startTime && endTime
    ? Math.floor((endTime.getTime() - startTime.getTime()) / 1000)
    : 0

  // Build PostGIS LineString WKT
  const lineString = trackPoints
    .map(p => `${p.lon} ${p.lat}`)
    .join(', ')
  const geomWKT = `SRID=4326;LINESTRING(${lineString})`

  return {
    distance_m: Math.round(totalDistance),
    duration_sec: durationSec,
    elevation_gain_m: Math.round(elevationGain),
    start_time: startTime,
    end_time: endTime,
    start_lat: trackPoints[0].lat,
    start_lon: trackPoints[0].lon,
    end_lat: trackPoints[trackPoints.length - 1].lat,
    end_lon: trackPoints[trackPoints.length - 1].lon,
    geom: geomWKT,
  }
}

// Simplified TCX parser
async function parseTCX(content: string): Promise<any> {
  // Similar to GPX but with TCX XML structure
  // In production, use proper XML parser
  return parseGPX(content) // Fallback to GPX parser for now
}

// Haversine distance formula (meters)
function haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3 // Earth radius in meters
  const φ1 = lat1 * Math.PI / 180
  const φ2 = lat2 * Math.PI / 180
  const Δφ = (lat2 - lat1) * Math.PI / 180
  const Δλ = (lon2 - lon1) * Math.PI / 180

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  
  return R * c
}

