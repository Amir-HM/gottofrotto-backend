import type {
  SubscriberArgs,
  SubscriberConfig,
} from "@medusajs/framework"
import type { MedusaContainer, NotificationTypes } from "@medusajs/types"
import { AuthWorkflowEvents } from "@medusajs/framework/utils"

type LoggerLike = {
  debug?: (...args: unknown[]) => void
  info?: (...args: unknown[]) => void
  warn?: (...args: unknown[]) => void
  error?: (...args: unknown[]) => void
}

type NotificationServiceLike = {
  createNotifications: (
    payload: Parameters<NotificationTypes.INotificationModuleService["createNotifications"]>[0]
  ) => Promise<NotificationTypes.NotificationDTO | NotificationTypes.NotificationDTO[]>
}

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

  try {
    const notifications = await notificationService.createNotifications({
      to: recipient,
      channel: DEFAULT_CHANNEL,
      template: DEFAULT_TEMPLATE,
      trigger_type: AuthWorkflowEvents.PASSWORD_RESET,
      data: {
        actor_type,
        reset_url: resetUrl,
      },
      content: {
        subject,
        text,
        html,
      },
    })

    const normalized = Array.isArray(notifications)
      ? notifications
      : [notifications as NotificationTypes.NotificationDTO]

    const failed = normalized.filter(
      (notification) => notification.status !== "success"
    )

    if (failed.length) {
      logger?.error?.(
        "[notification][resend] Failed to dispatch password reset email",
        failed
      )
    } else {
      logger?.info?.(
        "[notification][resend] Password reset email queued successfully",
        {
          to: recipient,
          actor_type,
        }
      )
    }
  } catch (err) {
    logger?.error?.(
      "[notification][resend] Unhandled error sending password reset email",
      err
    )
  }
}

export const config: SubscriberConfig = {
  event: AuthWorkflowEvents.PASSWORD_RESET,
}

const resolveNotificationService = (
  container: MedusaContainer,
  logger?: LoggerLike
): NotificationServiceLike | null => {
  const candidates = ["notification", "notificationModuleService"]
  for (const key of candidates) {
    try {
      return container.resolve(key) as NotificationServiceLike
    } catch (error) {
      logger?.debug?.(
        `[notification][resend] Unable to resolve container key "${key}": ${(error as Error).message}`
      )
    }
  }
  return null
}

const resolveLogger = (container: MedusaContainer): LoggerLike => {
  try {
    return container.resolve("logger") as LoggerLike
  } catch {
    return console
  }
}

type ConfigModuleLike = {
  admin?: { path?: string }
  projectConfig?: { http?: { adminCors?: string } }
}

const buildResetPasswordUrl = (
  container: MedusaContainer,
  token: string,
  actorType: string
) => {
  const configModule = safeResolve<ConfigModuleLike>(container, "configModule") ?? {}
  const adminPath = configModule.admin?.path ?? "/app"

  // Only use explicit, intentional URL env vars for the reset link base.
  // Mining the CORS allowlist for an origin used to leak localhost/wildcards
  // into production emails.
  const baseCandidates = [
    process.env.ADMIN_RESET_PASSWORD_URL,
    process.env.ADMIN_PUBLIC_URL,
    process.env.ADMIN_BASE_URL,
    process.env.BACKEND_URL,
    process.env.MEDUSA_BACKEND_URL,
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

const safeResolve = <T>(container: MedusaContainer, key: string): T | undefined => {
  try {
    return container.resolve(key) as T
  } catch {
    return undefined
  }
}
