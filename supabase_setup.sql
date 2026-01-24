-- Modify existing users table to work with Supabase auth
alter table public.users 
  alter column id drop default,
  alter column id type uuid using id::uuid,
  add constraint users_id_fkey foreign key (id) references auth.users(id) on delete cascade;

-- Add missing columns for app functionality
alter table public.users 
  add column if not exists xp integer default 0,
  add column if not exists streak integer default 0,
  add column if not exists lastActiveDate timestamp with time zone default timezone('utc'::text, now()),
  add column if not exists dailyGoal integer default 100,
  add column if not exists dailyXpEarned integer default 0,
  add column if not exists settings jsonb default '{}',
  add column if not exists onboarding_completed boolean default false;

-- Create profiles table for Supabase auth integration
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  full_name text,
  email text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.users enable row level security;

-- Create policies for profiles table
create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update their own profile." on profiles
  for update using (auth.uid() = id);

-- Create policies for users table
create policy "Users can view their own data." on users
  for select using (auth.uid() = id);

create policy "Users can insert their own data." on users
  for insert with check (auth.uid() = id);

create policy "Users can update their own data." on users
  for update using (auth.uid() = id);

-- Create function to handle new user creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  -- Insert into profiles table
  insert into public.profiles (id, full_name, email, created_at)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email, new.created_at);
  
  -- Insert into users table
  insert into public.users (id, name, email, created_at, updated_at)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email, new.created_at, new.created_at);
  
  return new;
end;
$$ language plpgsql security definer;

-- Create trigger for new user creation
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();