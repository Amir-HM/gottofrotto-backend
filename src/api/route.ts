import type { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(req: MedusaRequest, res: MedusaResponse) {
  res.status(200).json({
    message: "🎉 Gottofrotto Backend is Live!",
    version: "2.0", 
    apis: {
      store: "/store",
      admin: "/admin",
      adminUI: "/app",
      health: "/health"
    },
    status: "operational",
    timestamp: new Date().toISOString()
  })
}