/*
  # Create profiles and PDF uploads tables

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key)
      - `full_name` (text)
      - `group_name` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `pdf_uploads`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `filename` (text)
      - `file_size` (bigint)
      - `mime_type` (text)
      - `status` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add appropriate policies for authenticated users
*/

-- Create profiles table first
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  group_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create function to handle updated_at if it doesn't exist
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for profiles
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Now create PDF uploads table
CREATE TABLE pdf_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  filename TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on pdf_uploads
ALTER TABLE pdf_uploads ENABLE ROW LEVEL SECURITY;

-- Create policies for pdf_uploads
CREATE POLICY "Users can insert their own uploads"
  ON pdf_uploads
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own uploads"
  ON pdf_uploads
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create trigger for pdf_uploads
CREATE TRIGGER update_pdf_uploads_updated_at
  BEFORE UPDATE ON pdf_uploads
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();