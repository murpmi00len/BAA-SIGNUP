/*
  # Create PDF uploads table

  1. New Tables
    - `pdf_uploads`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `filename` (text)
      - `file_size` (bigint)
      - `mime_type` (text)
      - `status` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `pdf_uploads` table
    - Add policies for authenticated users to:
      - Insert their own uploads
      - View their own uploads
*/

-- Create PDF uploads table
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

-- Enable RLS
ALTER TABLE pdf_uploads ENABLE ROW LEVEL SECURITY;

-- Create policies
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

-- Create trigger for updated_at
CREATE TRIGGER update_pdf_uploads_updated_at
  BEFORE UPDATE ON pdf_uploads
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();