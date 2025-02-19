/*
  # Add PDF content storage

  1. New Tables
    - `pdf_contents`
      - `id` (uuid, primary key)
      - `upload_id` (uuid, references pdf_uploads)
      - `content` (bytea, stores the actual PDF file)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `pdf_contents` table
    - Add policies for authenticated users to manage their own PDF contents
*/

-- Create PDF contents table
CREATE TABLE IF NOT EXISTS public.pdf_contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_id UUID REFERENCES public.pdf_uploads(id) ON DELETE CASCADE NOT NULL,
  content BYTEA NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.pdf_contents ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can insert their own pdf contents" ON public.pdf_contents;
  DROP POLICY IF EXISTS "Users can view their own pdf contents" ON public.pdf_contents;

  -- Create new policies
  CREATE POLICY "Users can insert their own pdf contents"
    ON public.pdf_contents
    FOR INSERT
    TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.pdf_uploads
        WHERE id = pdf_contents.upload_id
        AND user_id = auth.uid()
      )
    );

  CREATE POLICY "Users can view their own pdf contents"
    ON public.pdf_contents
    FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.pdf_uploads
        WHERE id = pdf_contents.upload_id
        AND user_id = auth.uid()
      )
    );
END $$;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_pdf_contents_updated_at ON public.pdf_contents;
CREATE TRIGGER update_pdf_contents_updated_at
  BEFORE UPDATE ON public.pdf_contents
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();