export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      accounts: {
        Row: {
          created_at: string
          display_name: string | null
          phone: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          display_name?: string | null
          phone?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          display_name?: string | null
          phone?: string | null
          user_id?: string
        }
        Relationships: []
      }
      admins: {
        Row: {
          created_at: string
          role: string
          user_id: string
        }
        Insert: {
          created_at?: string
          role?: string
          user_id: string
        }
        Update: {
          created_at?: string
          role?: string
          user_id?: string
        }
        Relationships: []
      }
      audit_log: {
        Row: {
          action: string
          actor: string | null
          after: Json | null
          at: string
          before: Json | null
          entity: string
          entity_id: string | null
          id: number
        }
        Insert: {
          action: string
          actor?: string | null
          after?: Json | null
          at?: string
          before?: Json | null
          entity: string
          entity_id?: string | null
          id?: never
        }
        Update: {
          action?: string
          actor?: string | null
          after?: Json | null
          at?: string
          before?: Json | null
          entity?: string
          entity_id?: string | null
          id?: never
        }
        Relationships: []
      }
      devices: {
        Row: {
          fingerprint: string
          first_seen: string
          id: string
          installed_from_store: boolean | null
          integrity_level: string
          label: string | null
          last_seen: string
          platform: string
          revoked_at: string | null
          user_id: string
        }
        Insert: {
          fingerprint: string
          first_seen?: string
          id?: string
          installed_from_store?: boolean | null
          integrity_level?: string
          label?: string | null
          last_seen?: string
          platform: string
          revoked_at?: string | null
          user_id: string
        }
        Update: {
          fingerprint?: string
          first_seen?: string
          id?: string
          installed_from_store?: boolean | null
          integrity_level?: string
          label?: string | null
          last_seen?: string
          platform?: string
          revoked_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
      license_issuances: {
        Row: {
          device_id: string
          id: number
          integrity_level: string
          issued_at: string
          key_id: string
          token_expires_at: string
          user_id: string
          valid_until: string
        }
        Insert: {
          device_id: string
          id?: never
          integrity_level: string
          issued_at?: string
          key_id: string
          token_expires_at: string
          user_id: string
          valid_until: string
        }
        Update: {
          device_id?: string
          id?: never
          integrity_level?: string
          issued_at?: string
          key_id?: string
          token_expires_at?: string
          user_id?: string
          valid_until?: string
        }
        Relationships: [
          {
            foreignKeyName: "license_issuances_device_id_fkey"
            columns: ["device_id"]
            isOneToOne: false
            referencedRelation: "devices"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount_fcfa: number
          created_at: string
          id: string
          method: string
          paid_at: string
          recorded_by: string | null
          reference: string | null
          subscription_id: string | null
          user_id: string
        }
        Insert: {
          amount_fcfa: number
          created_at?: string
          id?: string
          method: string
          paid_at?: string
          recorded_by?: string | null
          reference?: string | null
          subscription_id?: string | null
          user_id: string
        }
        Update: {
          amount_fcfa?: number
          created_at?: string
          id?: string
          method?: string
          paid_at?: string
          recorded_by?: string | null
          reference?: string | null
          subscription_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      plans: {
        Row: {
          active: boolean
          code: string
          max_devices: number
          name: string
          period_days: number
          price_fcfa: number
          sort_order: number
        }
        Insert: {
          active?: boolean
          code: string
          max_devices: number
          name: string
          period_days: number
          price_fcfa: number
          sort_order?: number
        }
        Update: {
          active?: boolean
          code?: string
          max_devices?: number
          name?: string
          period_days?: number
          price_fcfa?: number
          sort_order?: number
        }
        Relationships: []
      }
      subscriptions: {
        Row: {
          activated_by: string | null
          created_at: string
          id: string
          note: string | null
          plan_code: string
          revoked_at: string | null
          revoked_by: string | null
          starts_at: string
          status: string
          user_id: string
          valid_until: string
        }
        Insert: {
          activated_by?: string | null
          created_at?: string
          id?: string
          note?: string | null
          plan_code: string
          revoked_at?: string | null
          revoked_by?: string | null
          starts_at?: string
          status?: string
          user_id: string
          valid_until: string
        }
        Update: {
          activated_by?: string | null
          created_at?: string
          id?: string
          note?: string | null
          plan_code?: string
          revoked_at?: string | null
          revoked_by?: string | null
          starts_at?: string
          status?: string
          user_id?: string
          valid_until?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_plan_code_fkey"
            columns: ["plan_code"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["code"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_accounts: {
        Args: { lim?: number; off?: number; query?: string; status?: string }
        Returns: {
          active_devices: number
          created_at: string
          display_name: string
          email: string
          phone: string
          plan_name: string
          situation: string
          total: number
          user_id: string
          valid_until: string
        }[]
      }
      admin_activate_subscription: {
        Args: {
          amount_fcfa: number
          method: string
          note?: string
          plan: string
          reference?: string
          target_user: string
          until: string
        }
        Returns: string
      }
      admin_dashboard: { Args: never; Returns: Json }
      admin_devices: {
        Args: { lim?: number; off?: number; query?: string; scope?: string }
        Returns: {
          email: string
          first_seen: string
          id: string
          installed_from_store: boolean
          integrity_level: string
          label: string
          last_seen: string
          platform: string
          revoked_at: string
          total: number
          user_id: string
        }[]
      }
      admin_list: {
        Args: never
        Returns: {
          created_at: string
          email: string
          role: string
          user_id: string
        }[]
      }
      admin_me: { Args: never; Returns: string }
      admin_payments: {
        Args: {
          lim?: number
          off?: number
          query?: string
          since?: string
          until?: string
        }
        Returns: {
          amount_fcfa: number
          email: string
          id: string
          method: string
          paid_at: string
          plan_name: string
          recorded_by_email: string
          reference: string
          total: number
          total_amount_fcfa: number
          user_id: string
        }[]
      }
      admin_remove: { Args: { target: string }; Returns: undefined }
      admin_search_account: {
        Args: { query: string }
        Returns: {
          created_at: string
          display_name: string
          email: string
          phone: string
          user_id: string
        }[]
      }
      admin_set_role: {
        Args: { new_role: string; target_email: string }
        Returns: undefined
      }
      admin_subscriptions: {
        Args: { lim?: number; off?: number; query?: string; status?: string }
        Returns: {
          created_at: string
          email: string
          id: string
          note: string
          plan_code: string
          plan_name: string
          starts_at: string
          state: string
          total: number
          user_id: string
          valid_until: string
        }[]
      }
      is_admin: { Args: never; Returns: boolean }
      is_super_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const

