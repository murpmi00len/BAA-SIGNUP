import { openDB, DBSchema, IDBPDatabase } from 'idb';

interface FileDBSchema extends DBSchema {
  files: {
    key: string;
    value: {
      id: string;
      file: File;
      uploadedAt: number;
    };
  };
}

const DB_NAME = 'pdf-storage';
const STORE_NAME = 'files';

let db: IDBPDatabase<FileDBSchema> | null = null;

export async function initDB() {
  try {
    if (!db) {
      db = await openDB<FileDBSchema>(DB_NAME, 1, {
        upgrade(db) {
          if (!db.objectStoreNames.contains(STORE_NAME)) {
            db.createObjectStore(STORE_NAME, { keyPath: 'id' });
          }
        },
      });
    }
    return db;
  } catch (error) {
    console.error('Failed to initialize IndexedDB:', error);
    throw new Error('Failed to initialize local storage');
  }
}

export async function storeFile(id: string, file: File) {
  try {
    const database = await initDB();
    await database.put(STORE_NAME, {
      id,
      file,
      uploadedAt: Date.now(),
    });
  } catch (error) {
    console.error('Failed to store file:', error);
    throw new Error('Failed to store file locally');
  }
}

export async function getFile(id: string) {
  try {
    const database = await initDB();
    return database.get(STORE_NAME, id);
  } catch (error) {
    console.error('Failed to retrieve file:', error);
    throw new Error('Failed to retrieve file from local storage');
  }
}

export async function deleteFile(id: string) {
  try {
    const database = await initDB();
    await database.delete(STORE_NAME, id);
  } catch (error) {
    console.error('Failed to delete file:', error);
    throw new Error('Failed to delete file from local storage');
  }
}