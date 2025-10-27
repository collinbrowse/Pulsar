// Edge Function: leaderboard
// Purpose: Get segment leaderboard with optional filters (gender, age, weight)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const url = new URL(req.url)
    const segmentId = url.searchParams.get('segment_id')
    const gender = url.searchParams.get('gender')
    const ageMin = url.searchParams.get('age_min')
    const ageMax = url.searchParams.get('age_max')
    const limit = parseInt(url.searchParams.get('limit') || '50')

    if (!segmentId) {
      return new Response(
        JSON.stringify({ error: 'segment_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get segment details
    const { data: segment, error: segmentError } = await supabaseClient
      .from('segments')
      .select('segment_id, name, distance_m, elevation_gain_m')
      .eq('segment_id', segmentId)
      .single()

    if (segmentError || !segment) {
      return new Response(
        JSON.stringify({ error: 'Segment not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate birth year range from age
    const currentYear = new Date().getFullYear()
    const minBirthYear = ageMax ? currentYear - parseInt(ageMax) : null
    const maxBirthYear = ageMin ? currentYear - parseInt(ageMin) : null

    // Get leaderboard using database function
    const { data: leaderboard, error: leaderboardError } = await supabaseClient
      .rpc('get_segment_leaderboard', {
        p_segment_id: segmentId,
        p_gender: gender,
        p_min_birth_year: minBirthYear,
        p_max_birth_year: maxBirthYear,
        p_limit: limit,
      })

    if (leaderboardError) {
      console.error('Leaderboard error:', leaderboardError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch leaderboard', details: leaderboardError }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Format elapsed time for display
    const formattedLeaderboard = leaderboard?.map((entry: any) => ({
      ...entry,
      elapsed_time_formatted: formatTime(entry.elapsed_time_sec),
      avg_speed_kmh: entry.avg_speed_mps ? (entry.avg_speed_mps * 3.6).toFixed(2) : null,
      pace_min_per_km: entry.avg_speed_mps ? formatPace(entry.avg_speed_mps) : null,
    }))

    return new Response(
      JSON.stringify({
        segment: {
          segment_id: segment.segment_id,
          name: segment.name,
          distance_m: segment.distance_m,
          distance_km: (segment.distance_m / 1000).toFixed(2),
          elevation_gain_m: segment.elevation_gain_m,
        },
        filters: {
          gender: gender || 'all',
          age_range: ageMin || ageMax ? `${ageMin || '0'}-${ageMax || '100+'}` : 'all',
        },
        leaderboard: formattedLeaderboard,
        total_entries: formattedLeaderboard?.length || 0,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Format seconds to HH:MM:SS
function formatTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
  }
  return `${minutes}:${String(secs).padStart(2, '0')}`
}

// Format pace (min/km)
function formatPace(speedMps: number): string {
  if (speedMps === 0) return '--:--'
  
  const paceSecPerKm = 1000 / speedMps
  const minutes = Math.floor(paceSecPerKm / 60)
  const seconds = Math.floor(paceSecPerKm % 60)
  
  return `${minutes}:${String(seconds).padStart(2, '0')}`
}

