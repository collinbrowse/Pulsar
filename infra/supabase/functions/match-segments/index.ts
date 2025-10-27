// Edge Function: match-segments
// Purpose: Find intersecting segments for an activity and create segment_efforts

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
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // Use service role for admin access
    )

    const { activity_id, activity_geom, activity_type } = await req.json()

    if (!activity_id || !activity_geom) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get activity details
    const { data: activity, error: activityError } = await supabaseClient
      .from('activities')
      .select('user_id, start_time, duration_sec')
      .eq('activity_id', activity_id)
      .single()

    if (activityError || !activity) {
      return new Response(
        JSON.stringify({ error: 'Activity not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user profile for leaderboard context
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('gender, birth_year, weight_kg')
      .eq('user_id', activity.user_id)
      .single()

    // Find matching segments using PostGIS function
    const { data: matchingSegments, error: segmentsError } = await supabaseClient
      .rpc('find_matching_segments', {
        p_activity_geom: activity_geom,
        p_activity_type: activity_type,
        p_tolerance: 50.0, // 50 meters tolerance
      })

    if (segmentsError) {
      console.error('Segment matching error:', segmentsError)
      return new Response(
        JSON.stringify({ error: 'Failed to match segments', details: segmentsError }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create segment efforts for matched segments
    const efforts = []
    
    for (const segment of matchingSegments || []) {
      if (segment.match_percentage >= 80) { // Only create efforts for >80% match
        // Calculate elapsed time for this segment (simplified)
        // In production, would calculate based on GPS timestamps within segment bounds
        const segmentDurationSec = Math.floor(
          activity.duration_sec * (segment.match_percentage / 100)
        )

        const effortData = {
          segment_id: segment.segment_id,
          activity_id: activity_id,
          user_id: activity.user_id,
          elapsed_time_sec: segmentDurationSec,
          distance_m: 0, // Would calculate from PostGIS
          effort_date: new Date(activity.start_time).toISOString().split('T')[0],
          user_gender: profile?.gender,
          user_birth_year: profile?.birth_year,
          user_weight_kg: profile?.weight_kg,
        }

        const { data: effort, error: effortError } = await supabaseClient
          .from('segment_efforts')
          .insert(effortData)
          .select()
          .single()

        if (!effortError) {
          efforts.push(effort)
        } else {
          console.error('Failed to create effort:', effortError)
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        segments_matched: matchingSegments?.length || 0,
        efforts_created: efforts.length,
        efforts,
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

