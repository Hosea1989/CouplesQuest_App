/// <reference types="https://deno.land/x/deploy@0.12.0/types.d.ts" />
// @ts-nocheck — This file runs on Supabase's Deno runtime, not Node/TSC.
// supabase/functions/send-push/index.ts
// Supabase Edge Function that sends push notifications to a target user
// via the OneSignal REST API.
//
// Deploy: supabase functions deploy send-push
// Set secret: supabase secrets set ONESIGNAL_REST_API_KEY=your_key ONESIGNAL_APP_ID=your_app_id

const ONESIGNAL_API_URL = "https://api.onesignal.com/notifications";

interface PushPayload {
  targetUserID: string;
  title: string;
  body: string;
  type?: string;
  data?: Record<string, string>;
}

Deno.serve(async (req: Request) => {
  // Only allow POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const payload: PushPayload = await req.json();
    const { targetUserID, title, body, type, data } = payload;

    if (!targetUserID || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: targetUserID, title, body" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Read secrets from Supabase environment
    const restApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");
    const appId = Deno.env.get("ONESIGNAL_APP_ID");

    if (!restApiKey || !appId) {
      console.error("Missing ONESIGNAL_REST_API_KEY or ONESIGNAL_APP_ID secrets");
      return new Response(
        JSON.stringify({ error: "Server misconfiguration" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Build OneSignal notification payload
    const onesignalPayload = {
      app_id: appId,
      include_aliases: {
        external_id: [targetUserID],
      },
      target_channel: "push",
      headings: { en: title },
      contents: { en: body },
      data: {
        type: type || "general",
        ...data,
      },
    };

    // Send via OneSignal REST API
    const response = await fetch(ONESIGNAL_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${restApiKey}`,
      },
      body: JSON.stringify(onesignalPayload),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("OneSignal API error:", JSON.stringify(result));
      return new Response(
        JSON.stringify({ error: "OneSignal API error", details: result }),
        { status: response.status, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, onesignal_id: result.id }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("send-push error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
