/*
  # PDF Uploads and Returns Management

  1. New Tables
    - `pdf_returns` table for tracking returned PDFs
      - `id` (uuid, primary key)
      - `upload_id` (uuid, references pdf_uploads)
      - `return_date` (timestamptz)
      - `status` (text)
      - `notes` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Changes
    - Add `return_status` column to `pdf_uploads`
    - Add `return_date` column to `pdf_uploads`

  3. Security
    - Enable RLS on new table
    - Add policies for authenticated users
*/

-- Add new columns to pdf_uploads
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pdf_uploads' AND column_name = 'return_status'
  ) THEN
    ALTER TABLE public.pdf_uploads ADD COLUMN return_status TEXT DEFAULT 'pending';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pdf_uploads' AND column_name = 'return_date'
  ) THEN
    ALTER TABLE public.pdf_uploads ADD COLUMN return_date TIMESTAMPTZ;
  END IF;
END $$;

-- Create pdf_returns table
CREATE TABLE IF NOT EXISTS public.pdf_returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_id UUID REFERENCES public.pdf_uploads(id) ON DELETE CASCADE NOT NULL,
  return_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.pdf_returns ENABLE ROW LEVEL SECURITY;

-- Create policies for pdf_returns
DO $$ 
BEGIN
  -- Create insert policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can create returns for their uploads'
  ) THEN
    CREATE POLICY "Users can create returns for their uploads"
      ON public.pdf_returns
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.pdf_uploads
          WHERE id = pdf_returns.upload_id
          AND user_id = auth.uid()
        )
      );
  END IF;

  -- Create select policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own returns'
  ) THEN
    CREATE POLICY "Users can view their own returns"
      ON public.pdf_returns
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.pdf_uploads
          WHERE id = pdf_returns.upload_id
          AND user_id = auth.uid()
        )
      );
  END IF;

  -- Create update policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own returns'
  ) THEN
    CREATE POLICY "Users can update their own returns"
      ON public.pdf_returns
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.pdf_uploads
          WHERE id = pdf_returns.upload_id
          AND user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Create trigger for updated_at
CREATE TRIGGER update_pdf_returns_updated_at
  BEFORE UPDATE ON public.pdf_returns
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();