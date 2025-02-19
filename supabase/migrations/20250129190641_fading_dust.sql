/*
  # Fix database schema

  1. Tables
    - Ensure `groups` table exists with correct structure
    - Ensure `profiles` table exists with correct structure
    - Ensure `pdf_uploads` table exists with correct structure
    - Ensure `pdf_contents` table exists with correct structure

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for authenticated users
*/

-- Create groups table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.groups (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

-- Insert default groups if they don't exist
INSERT INTO public.groups (name)
VALUES ('Tech'), ('Marketing'), ('Finance'), ('HR')
ON CONFLICT (name) DO NOTHING;

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  group_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create PDF uploads table if it doesn't exist
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

-- Create PDF contents table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.pdf_contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_id UUID REFERENCES public.pdf_uploads(id) ON DELETE CASCADE NOT NULL,
  content BYTEA NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_contents ENABLE ROW LEVEL SECURITY;

-- Create or replace function for updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create policies if they don't exist
DO $$ 
BEGIN
  -- Groups policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Anonymous can view groups'
  ) THEN
    CREATE POLICY "Anonymous can view groups"
      ON public.groups
      FOR SELECT
      TO public
      USING (true);
  END IF;

  -- Profiles policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own profile'
  ) THEN
    CREATE POLICY "Users can view own profile"
      ON public.profiles
      FOR SELECT
      TO authenticated
      USING (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile"
      ON public.profiles
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own profile'
  ) THEN
    CREATE POLICY "Users can insert own profile"
      ON public.profiles
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;

  -- PDF uploads policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own uploads'
  ) THEN
    CREATE POLICY "Users can insert their own uploads"
      ON public.pdf_uploads
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own uploads'
  ) THEN
    CREATE POLICY "Users can view their own uploads"
      ON public.pdf_uploads
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;

  -- PDF contents policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own pdf contents'
  ) THEN
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
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own pdf contents'
  ) THEN
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
  END IF;
END $$;

-- Create triggers if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_profiles_updated_at'
  ) THEN
    CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON public.profiles
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_pdf_uploads_updated_at'
  ) THEN
    CREATE TRIGGER update_pdf_uploads_updated_at
      BEFORE UPDATE ON public.pdf_uploads
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_pdf_contents_updated_at'
  ) THEN
    CREATE TRIGGER update_pdf_contents_updated_at
      BEFORE UPDATE ON public.pdf_contents
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;
END $$;