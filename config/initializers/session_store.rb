# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_farmfacts_session',
  :secret      => 'fc589f826ee08866bc837ba4ff9cb9a0f072728fabc97df9694948234a6eb365d0f205aa52f71e96462e357c5615bc41a57d46307daaa85fe8ef348e085901d0'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
