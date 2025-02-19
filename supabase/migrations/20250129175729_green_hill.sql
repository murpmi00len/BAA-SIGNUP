/*
  # Add file storage columns to pdf_uploads table

  1. Changes
    - Add `file_path` column to store the storage path
    - Add `public_url` column to store the public access URL
  
  2. Security
    - Maintains existing RLS policies
    - No changes to security rules needed
*/

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pdf_uploads' AND column_name = 'file_path'
  ) THEN
    ALTER TABLE pdf_uploads ADD COLUMN file_path TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pdf_uploads' AND column_name = 'public_url'
  ) THEN
    ALTER TABLE pdf_uploads ADD COLUMN public_url TEXT;
  END IF;
END $$;