export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      mt5_accounts: {
        Row: {
          id: string;
          account_number: string;
          account_name: string;
          broker: string;
          currency: string;
          leverage: number;
          balance: number;
          equity: number;
          margin: number;
          free_margin: number;
          margin_level: number | null;
          floating_pl: number;
          swap: number;
          commission: number;
          last_updated: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          account_number: string;
          account_name: string;
          broker?: string;
          currency?: string;
          leverage?: number;
          balance?: number;
          equity?: number;
          margin?: number;
          free_margin?: number;
          margin_level?: number | null;
          floating_pl?: number;
          swap?: number;
          commission?: number;
          last_updated?: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          account_number?: string;
          account_name?: string;
          broker?: string;
          currency?: string;
          leverage?: number;
          balance?: number;
          equity?: number;
          margin?: number;
          free_margin?: number;
          margin_level?: number | null;
          floating_pl?: number;
          swap?: number;
          commission?: number;
          last_updated?: string;
          created_at?: string;
        };
        Relationships: [];
      };
      mt5_positions: {
        Row: {
          id: string;
          account_id: string;
          ticket: number;
          symbol: string;
          type: 'buy' | 'sell';
          volume: number;
          open_price: number;
          current_price: number | null;
          sl: number | null;
          tp: number | null;
          profit: number;
          swap: number;
          commission: number;
          open_time: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          account_id: string;
          ticket: number;
          symbol: string;
          type: 'buy' | 'sell';
          volume: number;
          open_price: number;
          current_price?: number | null;
          sl?: number | null;
          tp?: number | null;
          profit?: number;
          swap?: number;
          commission?: number;
          open_time: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          account_id?: string;
          ticket?: number;
          symbol?: string;
          type?: 'buy' | 'sell';
          volume?: number;
          open_price?: number;
          current_price?: number | null;
          sl?: number | null;
          tp?: number | null;
          profit?: number;
          swap?: number;
          commission?: number;
          open_time?: string;
          created_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'mt5_positions_account_id_fkey';
            columns: ['account_id'];
            referencedRelation: 'mt5_accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      mt5_trade_history: {
        Row: {
          id: string;
          account_id: string;
          ticket: number;
          symbol: string;
          type: 'buy' | 'sell';
          volume: number;
          open_price: number;
          close_price: number;
          profit: number;
          swap: number;
          commission: number;
          open_time: string;
          close_time: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          account_id: string;
          ticket: number;
          symbol: string;
          type: 'buy' | 'sell';
          volume: number;
          open_price: number;
          close_price: number;
          profit?: number;
          swap?: number;
          commission?: number;
          open_time: string;
          close_time: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          account_id?: string;
          ticket?: number;
          symbol?: string;
          type?: 'buy' | 'sell';
          volume?: number;
          open_price?: number;
          close_price?: number;
          profit?: number;
          swap?: number;
          commission?: number;
          open_time?: string;
          close_time?: string;
          created_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'mt5_trade_history_account_id_fkey';
            columns: ['account_id'];
            referencedRelation: 'mt5_accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      frameworks: {
        Row: {
          description: string;
          created_at: string;
          url: string;
          id: string;
          logo: string;
          name: string;
          likes: number;
        };
        Insert: {
          description: string;
          created_at?: string;
          url: string;
          id?: string;
          logo: string;
          name: string;
          likes?: number;
        };
        Update: {
          description?: string;
          created_at?: string;
          url?: string;
          id?: string;
          logo?: string;
          name?: string;
          likes?: number;
        };
        Relationships: [];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type PublicSchema = Database[Extract<keyof Database, "public">];

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never;
