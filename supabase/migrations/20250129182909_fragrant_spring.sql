/*
  # PDF Uploads Schema

  1. Tables
    - Creates pdf_uploads table for storing file metadata
  
  2. Security
    - Enables RLS
    - Sets up appropriate access policies
    - Adds updated_at trigger functionality

  3. Columns
    - id: Unique identifier
    - user_id: Reference to profiles table
    - filename: Original file name
    - file_size: Size in bytes
    - mime_type: File MIME type
    - status: Upload status
    - file_path: Storage path
    - public_url: Public access URL
*/

-- Create PDF uploads table
CREATE TABLE IF NOT EXISTS public.pdf_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  filename TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  file_path TEXT,
  public_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.pdf_uploads ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can insert their own uploads" ON public.pdf_uploads;
  DROP POLICY IF EXISTS "Users can view their own uploads" ON public.pdf_uploads;

  -- Create new policies
  CREATE POLICY "Users can insert their own uploads"
    ON public.pdf_uploads
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

  CREATE POLICY "Users can view their own uploads"
    ON public.pdf_uploads
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_pdf_uploads_updated_at ON public.pdf_uploads;
CREATE TRIGGER update_pdf_uploads_updated_at
  BEFORE UPDATE ON public.pdf_uploads
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();