/*
  # Fix database schema with proper table order

  1. Tables (in order)
    - groups
    - profiles (depends on auth.users)
    - pdf_uploads (depends on profiles)
  
  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for each table
    - Maintain existing security rules
*/

-- Create groups table if it doesn't exist
CREATE TABLE IF NOT EXISTS groups (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

-- Insert default groups if they don't exist
INSERT INTO groups (name)
VALUES ('Tech'), ('Marketing'), ('Finance'), ('HR')
ON CONFLICT (name) DO NOTHING;

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  group_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create PDF uploads table if it doesn't exist
CREATE TABLE IF NOT EXISTS pdf_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
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
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdf_uploads ENABLE ROW LEVEL SECURITY;

-- Create or replace function for updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create policies for groups
CREATE POLICY IF NOT EXISTS "Anonymous can view groups"
  ON groups
  FOR SELECT
  TO public
  USING (true);

-- Create policies for profiles
CREATE POLICY IF NOT EXISTS "Users can view own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Users can insert own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create policies for pdf_uploads
CREATE POLICY IF NOT EXISTS "Users can insert their own uploads"
  ON pdf_uploads
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can view their own uploads"
  ON pdf_uploads
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS update_pdf_uploads_updated_at ON pdf_uploads;
CREATE TRIGGER update_pdf_uploads_updated_at
  BEFORE UPDATE ON pdf_uploads
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();