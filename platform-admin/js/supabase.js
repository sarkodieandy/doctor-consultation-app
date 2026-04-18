// Supabase Configuration for Admin Dashboard
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = 'https://ijmblflyhhuoftesjsmi.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqbWJsZmx5aGh1b2Z0ZXNqc21pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0ODcxNzQsImV4cCI6MjA4NzA2MzE3NH0.jVu4mpsB3n4-iVHBE0ihrztXigQ5M3HTGhrMAoI87oU';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
