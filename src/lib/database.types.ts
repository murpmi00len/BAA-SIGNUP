export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          full_name: string;
          group_name: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          full_name: string;
          group_name: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          full_name?: string;
          group_name?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
      groups: {
        Row: {
          id?: string;
          name: 'Tech' | 'Marketing' | 'Finance' | 'HR';
        };
        Insert: {
          id?: string;
          name: 'Tech' | 'Marketing' | 'Finance' | 'HR';
        };
        Update: {
          id?: string;
          name?: 'Tech' | 'Marketing' | 'Finance' | 'HR';
        };
      };
      pdf_uploads: {
        Row: {
          id: string;
          user_id: string;
          filename: string;
          file_size: number;
          mime_type: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          filename: string;
          file_size: number;
          mime_type: string;
          status?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          filename?: string;
          file_size?: number;
          mime_type?: string;
          status?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
      pdf_contents: {
        Row: {
          id: string;
          upload_id: string;
          content: Uint8Array;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          upload_id: string;
          content: Uint8Array;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          upload_id?: string;
          content?: Uint8Array;
          created_at?: string;
          updated_at?: string;
        };
      };
    };
  };
}