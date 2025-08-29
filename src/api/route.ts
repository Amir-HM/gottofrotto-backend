import type { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(req: MedusaRequest, res: MedusaResponse) {
  res.json({
    message: "🎉 Gottofrotto Backend is Live!",
    version: "2.0",
    apis: {
      store: "/store",
      admin: "/admin", 
      health: "/health"
    },
    status: "operational"
  })
}