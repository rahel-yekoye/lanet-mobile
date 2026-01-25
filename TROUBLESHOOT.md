# Troubleshooting Supabase Authentication Issues

## Common Issues and Solutions

### 1. Network/Connection Issues
The error `AuthRetryableFetchException(message: ClientException: Failed to fetch)` typically indicates:
- Poor internet connection
- Firewall blocking requests
- Invalid Supabase URL or API key

### 2. Supabase Configuration
Your current Supabase configuration is in `lib/config/supabase_config.dart`:
- URL: `https://dvjwoggpbhxygrhfraut.supabase.co`
- Anon Key: `sb_publishable_gmm2eBcmqVtPQYgC6ibQJA_zKApKLxv`

### 3. How to Fix Authentication Issues

#### Option 1: Verify Current Supabase Project
1. Log in to your Supabase dashboard at [supabase.com](https://supabase.com/dashboard/)
2. Select your project
3. Go to Project Settings → API
4. Copy the "Project URL" and "anon key"
5. Update `lib/config/supabase_config.dart` with the correct values

#### Option 2: Create a New Supabase Project
1. Go to [supabase.com](https://supabase.com/) and create an account
2. Create a new project
3. Use the new project's URL and anon key in `lib/config/supabase_config.dart`

#### Option 3: Database Schema
Make sure your Supabase project has the required tables:
- `auth.users` (automatically created by Supabase Auth)
- `public.users`
- `public.profiles`
- `public.user_preferences`

Run the following SQL in your Supabase SQL Editor to ensure tables exist:

```sql
-- Make sure you have the required tables
-- The SQL in supabase_setup.sql should be run in your Supabase SQL editor
```

### 4. Running the App
After updating your configuration:

1. Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### 5. Debugging Tips
- Check the debug console for detailed error messages
- Verify internet connectivity
- Ensure your Supabase project allows connections from your IP/domain
- Check Supabase project authentication settings

### 6. Supabase Authentication Settings
In your Supabase dashboard:
- Go to Authentication → Settings
- Ensure email sign-ins are enabled
- Check if email confirmation is required (the app is configured to disable it)

---

If you continue to have issues, verify that your Supabase project is active and that the URL/anon key are correct by testing them directly in the Supabase dashboard.