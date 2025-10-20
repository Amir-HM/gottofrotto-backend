import type {
  SubscriberArgs,
  SubscriberConfig,
} from "@medusajs/framework"
import { AuthWorkflowEvents } from "@medusajs/framework/utils"

type PasswordResetEvent = {
  entity_id: string
  actor_type: string
  token: string
}

const DEFAULT_TEMPLATE = "auth.password_reset"
const DEFAULT_CHANNEL = "email"

export default async function sendPasswordResetEmail({
  event,
  container,
}: SubscriberArgs<PasswordResetEvent>) {
  const { entity_id: recipient, actor_type, token } = event.data

  if (!recipient || !token) {
    return
  }

  const logger = resolveLogger(container)
  const notificationService = resolveNotificationService(container, logger)

  if (!notificationService) {
    logger?.warn?.(
      "[notification][resend] Notification module is not available. Skipping password reset email."
    )
    return
  }

  const resetUrl = buildResetPasswordUrl(container, token, actor_type)

  const subject =
    actor_type === "user"
      ? "Reset your admin password"
      : "Reset your password"

  const text =
    `You requested a password reset. Use the link below to choose a new password:\n\n${resetUrl}\n\n` +
    "This link expires in 15 minutes. If you didn’t request the reset you can ignore this email."

  const html = [
    "<p>You requested a password reset for your account.</p>",
    `<p><a href="${resetUrl}">Click here to choose a new password</a>.</p>`,
    "<p>This link expires in 15 minutes. If you didn’t request the reset you can ignore this email.</p>",
  ].join("")

  await notificationService.createNotifications({
    to: recipient,
    channel: DEFAULT_CHANNEL,
    template: DEFAULT_TEMPLATE,
    trigger_type: AuthWorkflowEvents.PASSWORD_RESET,
    data: {
      actor_type,
      reset_url: resetUrl,
      token,
    },
    content: {
      subject,
      text,
      html,
    },
  })
}

export const config: SubscriberConfig = {
  event: AuthWorkflowEvents.PASSWORD_RESET,
}

const resolveNotificationService = (container: any, logger?: LoggerType) => {
  const candidates = ["notification", "notificationModuleService"]
  for (const key of candidates) {
    try {
      return container.resolve(key)
    } catch (error) {
      logger?.debug?.(
        `[notification][resend] Unable to resolve container key "${key}": ${(error as Error).message}`
      )
    }
  }
  return null
}

const resolveLogger = (container: any): LoggerType | undefined => {
  try {
    return container.resolve("logger")
  } catch {
    return console
  }
}

const buildResetPasswordUrl = (
  container: any,
  token: string,
  actorType: string
) => {
  const configModule = safeResolve(container, "configModule") ?? {}
  const adminPath = (configModule.admin?.path as string) ?? "/app"

  const baseCandidates = [
    process.env.ADMIN_RESET_PASSWORD_URL,
    process.env.ADMIN_PUBLIC_URL,
    process.env.ADMIN_BASE_URL,
    process.env.BACKEND_URL,
    process.env.MEDUSA_BACKEND_URL,
    pickFirstOrigin(process.env.ADMIN_CORS),
    pickFirstOrigin(configModule.projectConfig?.http?.adminCors),
  ].filter(Boolean) as string[]

  const resetPath = normalizePath(`${adminPath}/reset-password`)

  for (const candidate of baseCandidates) {
    const absolute = buildUrl(candidate as string, resetPath, token, actorType)
    if (absolute) {
      return absolute
    }
  }

  return `${resetPath}?token=${encodeURIComponent(token)}`
}

const normalizePath = (path: string) =>
  `/${path.replace(/^\//, "").replace(/\/$/, "")}`

const buildUrl = (
  base: string,
  path: string,
  token: string,
  actorType: string
) => {
  const candidates = [base, ensureHttps(base)]

  for (const candidate of candidates) {
    if (!candidate) {
      continue
    }

    try {
      const url = new URL(candidate)
      url.pathname = path
      url.searchParams.set("token", token)
      if (actorType) {
        url.searchParams.set("actor_type", actorType)
      }
      return url.toString()
    } catch {
      continue
    }
  }

  return null
}

const ensureHttps = (value?: string) => {
  if (!value) {
    return value
  }

  if (/^https?:\/\//i.test(value)) {
    return value
  }

  return `https://${value}`
}

const pickFirstOrigin = (value?: string) => {
  if (!value) {
    return undefined
  }

  return value.split(",")[0]?.trim()
}

const safeResolve = (container: any, key: string) => {
  try {
    return container.resolve(key)
  } catch {
    return undefined
  }
}

type LoggerType = {
  debug?: (...args: any[]) => void
  warn?: (...args: any[]) => void
  error?: (...args: any[]) => void
}
