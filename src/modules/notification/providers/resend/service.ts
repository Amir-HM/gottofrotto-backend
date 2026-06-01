import { Resend } from "resend"

import {
  AbstractNotificationProviderService,
  MedusaError,
  MedusaErrorTypes,
} from "@medusajs/framework/utils"
import type {
  Logger,
  NotificationTypes,
} from "@medusajs/framework/types"

type InjectedDependencies = {
  logger?: Logger
}

type ResendProviderOptions = {
  api_key?: string
  from?: string
  channels?: string[]
}

/**
 * Notification provider that sends transactional emails using Resend.
 */
export default class ResendNotificationProviderService extends AbstractNotificationProviderService {
  static identifier = "resend"

  protected readonly logger_: Logger | Console
  protected readonly options_: ResendProviderOptions
  protected readonly client_: Resend

  constructor(
    { logger }: InjectedDependencies,
    options: ResendProviderOptions
  ) {
    super()

    this.logger_ = logger ?? console
    this.options_ = options ?? {}

    const apiKey =
      this.options_.api_key || process.env.RESEND_API_KEY

    if (!apiKey) {
      throw new MedusaError(
        MedusaErrorTypes.INVALID_DATA,
        "Resend provider requires an API key. Set it in the notification provider options or RESEND_API_KEY."
      )
    }

    this.client_ = new Resend(apiKey)
  }

  static validateOptions(options: ResendProviderOptions) {
    if (!options?.api_key && !process.env.RESEND_API_KEY) {
      throw new MedusaError(
        MedusaErrorTypes.INVALID_DATA,
        "Resend provider requires an `api_key` option or RESEND_API_KEY environment variable."
      )
    }

    if (!options?.from && !process.env.RESEND_FROM) {
      throw new MedusaError(
        MedusaErrorTypes.INVALID_DATA,
        "Resend provider requires a `from` option or RESEND_FROM environment variable."
      )
    }
  }

  async send(
    notification: NotificationTypes.ProviderSendNotificationDTO
  ): Promise<NotificationTypes.ProviderSendNotificationResultsDTO> {
    const from =
      notification.from ||
      this.options_.from ||
      process.env.RESEND_FROM

    if (!from) {
      throw new MedusaError(
        MedusaErrorTypes.INVALID_DATA,
        "Resend provider requires a sender address."
      )
    }

    // Only accept content from the typed `notification.content` envelope.
    // The `notification.data` bag is caller-controlled and could contain
    // attacker-supplied HTML if a future subscriber forwards user input.
    // Restricting source here closes that XSS-via-email channel at the
    // boundary instead of relying on every caller to do the right thing.
    const subject = notification.content?.subject || "Notification"
    const html = notification.content?.html || undefined
    const text =
      notification.content?.text ||
      (html ? stripHtml(html) : undefined)

    if (!html && !text) {
      throw new MedusaError(
        MedusaErrorTypes.INVALID_DATA,
        "Resend provider requires either HTML or plain-text content."
      )
    }

    try {
      const payload: Parameters<typeof this.client_.emails.send>[0] = {
        from,
        to: [notification.to],
        subject,
        // Invariant: the `!html && !text` guard above guarantees `text` is
        // defined here when `html` is not. The non-null assertion is the
        // narrowest way to communicate that to the compiler.
        ...(html ? { html } : { text: text! }),
      }

      // Cap the Resend round-trip so an outage doesn't pin a Node socket
      // for two minutes (Node's default). 10s is generous for transactional
      // email and aligns with how long we're willing to hold the password-
      // reset event-bus slot.
      const { data, error } = await withTimeout(
        this.client_.emails.send(payload),
        10_000,
        "resend"
      )

      if (error) {
        this.logger_.error?.(
          `[notification][resend] Failed to send message: ${error.message}`,
          error
        )
        throw new MedusaError(
          MedusaErrorTypes.UNEXPECTED_STATE,
          `Resend failed to send email: ${error.message}`
        )
      }

      return {
        id: data?.id,
      }
    } catch (err) {
      const error = err as Error
      this.logger_.error?.(
        "[notification][resend] Unexpected error while sending email",
        error
      )
      throw new MedusaError(
        MedusaErrorTypes.UNEXPECTED_STATE,
        `Resend email send failed: ${error.message}`
      )
    }
  }
}

const stripHtml = (value: string) =>
  value.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim()

const withTimeout = <T>(
  promise: Promise<T>,
  ms: number,
  label: string
): Promise<T> => {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`${label} request timed out after ${ms}ms`))
    }, ms)
    promise
      .then((value) => {
        clearTimeout(timer)
        resolve(value)
      })
      .catch((err) => {
        clearTimeout(timer)
        reject(err)
      })
  })
}
