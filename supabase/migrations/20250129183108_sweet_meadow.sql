/*
  # Update Profiles Table Schema

  1. Changes
    - Adds email column to profiles table
    - Updates timestamp type to TIMESTAMP
    - Makes full_name nullable
    - Adds gen_random_uuid() as default for id

  2. Security
    - Maintains existing RLS policies
*/

-- Add new columns and modify existing ones
DO $$ 
BEGIN
  -- Add email column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN email TEXT UNIQUE NOT NULL;
  END IF;

  -- Modify full_name to be nullable
  ALTER TABLE public.profiles ALTER COLUMN full_name DROP NOT NULL;

  -- Update id column to have gen_random_uuid() as default if it doesn't already
  ALTER TABLE public.profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();

  -- Convert created_at to TIMESTAMP if it's not already
  ALTER TABLE public.profiles 
    ALTER COLUMN created_at TYPE TIMESTAMP USING created_at::TIMESTAMP;
END $$;