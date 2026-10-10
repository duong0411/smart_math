import sqlite3
import numpy as np
import threading
from typing import List, Optional, Dict
from dataclasses import dataclass

@dataclass
class Person:
    id: int
    name: str

class CacheData:
    def __init__(self):
        self.vectors: np.ndarray = np.empty((0, 128), dtype=np.float32)
        self.person_ids: np.ndarray = np.empty((0,), dtype=np.int64)

class FaceDatabase:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._init_db()

    def _get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON;")
        return conn

    def _init_db(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS persons (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL
                )
            """)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS embeddings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    person_id INTEGER NOT NULL,
                    vector BLOB NOT NULL,
                    FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
                )
            """)
            conn.commit()

    def load_cache(self) -> CacheData:
        cache = CacheData()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT person_id, vector FROM embeddings")
            rows = cursor.fetchall()
            
            if rows:
                vectors = []
                p_ids = []
                for r in rows:
                    p_ids.append(r["person_id"])
                    v = np.frombuffer(r["vector"], dtype=np.float32)
                    vectors.append(v)
                    
                cache.vectors = np.stack(vectors)
                cache.person_ids = np.array(p_ids, dtype=np.int64)
                
        return cache

    def get_person(self, person_id: int) -> Optional[Person]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, name FROM persons WHERE id = ?", (person_id,))
            row = cursor.fetchone()
            if row:
                return Person(id=row["id"], name=row["name"])
        return None

    def delete_person(self, person_id: int):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM persons WHERE id = ?", (person_id,))
            conn.commit()

    def close(self):
        pass
