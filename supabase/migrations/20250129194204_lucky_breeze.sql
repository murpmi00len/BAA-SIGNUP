/*
  # PDF Uploads Table Creation

  1. New Table
    - `pdf_uploads` table for managing PDF file uploads
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `filename` (text)
      - `file_size` (bigint)
      - `mime_type` (text)
      - `status` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

-- Create PDF uploads table
CREATE TABLE IF NOT EXISTS public.pdf_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  filename TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.pdf_uploads ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$ 
BEGIN
  -- Create insert policy
  CREATE POLICY "Users can insert their own uploads"
    ON public.pdf_uploads
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

  -- Create select policy
  CREATE POLICY "Users can view their own uploads"
    ON public.pdf_uploads
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- Create trigger for updated_at
-- CREATE TRIGGER update_pdf_uploads_updated_at
--   BEFORE UPDATE ON public.pdf_uploads
--   FOR EACH ROW
--   EXECUTE FUNCTION public.handle_updated_at();