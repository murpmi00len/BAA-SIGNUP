import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut, Upload } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { initDB, storeFile } from '../lib/storage';

import type { Database } from '../lib/database.types';

type Profile = Database['public']['Tables']['profiles']['Row'];
type PdfUpload = Database['public']['Tables']['pdf_uploads']['Row'];

export function Dashboard() {
  const { session } = useAuth();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [uploads, setUploads] = useState<PdfUpload[]>([]);
  const [isUploading, setIsUploading] = useState(false);

  useEffect(() => {
    initDB().catch(error => {
      console.error('Failed to initialize storage:', error);
      setError('Failed to initialize local storage. Please refresh the page and try again.');
    });
  }, []);

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    setError(null);
    
    if (!file) return;
    
    // Check file size (50MB limit)
    if (file.size > 50 * 1024 * 1024) {
      setError('File size must be less than 50MB');
      return;
    }
    
    // Check file type
    if (file.type !== 'application/pdf' && !file.name.endsWith('.zip')) {
      setError('Only PDF and ZIP files are allowed');
      return;
    }

    setIsUploading(true);
    
    try {
      // Insert file metadata into database
      const { data: uploadData, error: uploadError } = await supabase
        .from('pdf_uploads')
        .insert({
          user_id: session?.user.id,
          filename: file.name,
          file_size: file.size,
          mime_type: file.type,
          status: 'stored_locally'
        })
        .select()
        .single();

      if (uploadError) throw uploadError;

      if (!uploadData) {
        throw new Error('No upload data returned from server');
      }

      // Store file locally
      await storeFile(uploadData.id, file);

      // Refresh uploads list
      await fetchUploads();
      
    } catch (err) {
      console.error('Error uploading file:', err);
      setError(err instanceof Error ? err.message : 'Failed to upload file. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  async function fetchUploads() {
    try {
      const { data, error } = await supabase
        .from('pdf_uploads')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setUploads(data || []);
    } catch (error) {
      console.error('Error fetching uploads:', error);
    }
  }

  useEffect(() => {
    async function getProfile() {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) throw new Error('No user found');

        const { data, error } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

        if (error) throw error;
        
        setProfile(data);
        await fetchUploads();
      } catch (error) {
        console.error('Error loading user data:', error);
      } finally {
        setIsLoading(false);
      }
    }

    getProfile();
  }, []);

  async function handleSignOut() {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold text-gray-900">PDF Processor</h1>
            </div>
            <div className="flex items-center gap-4">
              <div className="text-sm text-gray-600">
                {session?.user?.email} ({profile?.group_name})
              </div>
              <button
                onClick={handleSignOut}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <LogOut className="h-4 w-4 mr-2" />
                Sign out
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 sm:px-0">
          <div className="bg-white rounded-lg shadow">
            <div className="p-6">
              <div className="space-y-4">
                <h3 className="text-lg font-medium text-gray-900">Upload PDF</h3>
                <div className="border-2 border-gray-300 border-dashed rounded-lg p-12">
                  <div className="text-center space-y-2">
                    <Upload className="mx-auto h-12 w-12 text-gray-400" />
                    <div className="mt-4 flex text-sm text-gray-600 justify-center">
                      <label
                        htmlFor="file-upload"
                        className="relative cursor-pointer rounded-md font-medium text-indigo-600 hover:text-indigo-500"
                      >
                        <span>Upload a file</span>
                        <input 
                          id="file-upload" 
                          name="file-upload" 
                          type="file" 
                          className="sr-only" 
                          accept=".pdf,.zip" 
                          onChange={handleFileChange}
                          disabled={isUploading}
                        />
                      </label>
                      <p className="pl-1">or drag and drop</p>
                    </div>
                    <p className="text-xs text-gray-500">PDF or ZIP files up to 50MB</p>
                    {error && (
                      <p className="text-sm text-red-600 mt-2">{error}</p>
                    )}
                    {isUploading && (
                      <div className="mt-2 flex justify-center">
                        <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-indigo-600"></div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Uploads List */}
                <div className="mt-8">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Your Uploads</h3>
                  <div className="bg-white shadow overflow-hidden sm:rounded-md">
                    <ul className="divide-y divide-gray-200">
                      {uploads.map((upload) => (
                        <li key={upload.id} className="px-4 py-4">
                          <div className="flex items-center justify-between">
                            <div>
                              <p className="text-sm font-medium text-gray-900">{upload.filename}</p>
                              <p className="text-sm text-gray-500">
                                {new Date(upload.created_at).toLocaleDateString()} • 
                                {(upload.file_size / 1024 / 1024).toFixed(2)} MB • 
                                Status: {upload.status}
                              </p>
                            </div>
                          </div>
                        </li>
                      ))}
                      {uploads.length === 0 && (
                        <li className="px-4 py-4 text-sm text-gray-500 text-center">
                          No files uploaded yet
                        </li>
                      )}
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}