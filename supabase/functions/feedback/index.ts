import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const requiredKeys = [
  "id",
  "createdAt",
  "status",
  "source",
  "category",
  "platform",
  "appVersion",
  "locale",
  "message",
] as const;

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json(405, { ok: false, error: "Method not allowed" });
  }

  try {
    const payload = await request.json();

    for (const key of requiredKeys) {
      if (!payload?.[key]) {
        return json(400, {
          ok: false,
          error: `Missing required field: ${key}`,
        });
      }
    }

    const {
      id,
      createdAt,
      status,
      source,
      category,
      platform,
      appVersion,
      locale,
      email,
      message,
      ...metadata
    } = payload;

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return json(500, {
        ok: false,
        error: "Supabase environment variables are not configured",
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
      },
    });

    const { error } = await supabase.from("feedback_submissions").insert({
      id,
      created_at: createdAt,
      status,
      source,
      category,
      platform,
      app_version: appVersion,
      locale,
      email: email || null,
      message,
      metadata,
    });

    if (error) {
      console.error("Failed to insert feedback submission", error);
      return json(500, { ok: false, error: "Failed to store feedback" });
    }

    return json(201, { ok: true, id });
  } catch (error) {
    console.error("Unexpected feedback function error", error);
    return json(500, { ok: false, error: "Unexpected feedback error" });
  }
});
