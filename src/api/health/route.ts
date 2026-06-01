import type { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(_req: MedusaRequest, res: MedusaResponse) {
  // Cheap, no DB ping. Don't add a timestamp — public health endpoints
  // should leak as little as possible.
  res.status(200).json({ status: "ok" })
}
