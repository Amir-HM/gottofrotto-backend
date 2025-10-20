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

    const subject =
      notification.content?.subject ||
      (notification.data?.subject as string) ||
      "Notification"

    const html =
      notification.content?.html ||
      (notification.data?.html as string) ||
      undefined

    const text =
      notification.content?.text ||
      (notification.data?.text as string) ||
      (html ? stripHtml(html) : undefined)

    if (!html && !text) {
      throw new MedusaError(
        MedusaErrorTypes.INVALID_DATA,
        "Resend provider requires either HTML or plain-text content."
      )
    }

    try {
      const payload: any = {
        from,
        to: [notification.to],
        subject,
        html: html ?? undefined,
        text: text ?? undefined,
      }

      const { data, error } = await this.client_.emails.send(payload)

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
