# Codemagic setup — OnAirFree

Repo: **https://github.com/congiirepair/OnAirFree** (private)
Everything code-side is done. This is the click-by-click for the account/key parts.

There are two phases. **Do Phase 1 first — it's free and needs no Apple account.**

---

## Phase 1 — Free compile check (do this now)

Goal: confirm the app builds on a real Mac and fix any first-build Swift errors,
before spending anything.

1. Go to **https://codemagic.io** → **Sign up** → **Sign in with GitHub** → authorize.
2. Codemagic asks to install its GitHub app. Grant access to the **OnAirFree** repo
   (you can limit it to just that repo).
3. **Add application** → pick **GitHub** → choose **congiirepair/OnAirFree** →
   it auto-detects `codemagic.yaml`.
4. Click **Start new build** → select workflow **“Build check (no signing)”** → **Start build**.
5. It spins up a Mac, runs `xcodegen generate`, and compiles for the simulator.
   - ✅ Green = the code compiles.
   - ❌ Red = open the log, copy the errors, **send them to me and I'll fix the Swift.**

No Apple account, no signing, no cost beyond free-tier minutes.

---

## Phase 2 — Build to your iPhone via TestFlight

Needed because a cloud Mac can't see your iPhone over USB — TestFlight is how the
build reaches your phone (and, later, the public).

### 2a. Apple Developer Program ($99/yr)
- Enroll at **https://developer.apple.com/programs/enroll/** with your Apple ID.
- Activation can take anywhere from minutes to a day.

### 2b. Create an App Store Connect API key (this is what Codemagic uses to sign & upload)
1. **https://appstoreconnect.apple.com** → **Users and Access** → **Integrations** tab
   → **App Store Connect API** → **Team Keys** → **(+)**.
2. Name it e.g. `codemagic`, Access = **App Manager** → **Generate**.
3. **Download the `.p8` key file** (you can only download it once — keep it safe).
4. Note the **Key ID** (next to the key) and the **Issuer ID** (top of the page).

### 2c. Register the app record
1. Still in App Store Connect → **Apps** → **(+) New App**.
2. Platform **iOS**, Name **OnAir** (must be unique on the App Store — if taken, try
   “OnAir Suspension” etc.), Primary language, Bundle ID **com.masoairOnair.onairfree**
   (if it's not in the dropdown yet, Codemagic will create it on first signed build,
   or add it under Certificates, Identifiers & Profiles → Identifiers → (+)).
   SKU can be anything, e.g. `onairfree`.

### 2d. Give Codemagic the API key
1. In Codemagic: **Teams → (your team) → Integrations → Developer Portal / App Store
   Connect → Manage keys → Add key**.
2. **Name it exactly `CODEMAGIC_ASC_KEY`** (this matches `codemagic.yaml`).
3. Paste **Issuer ID**, **Key ID**, and upload the **`.p8`** file. Save.

### 2e. Run it
1. Codemagic → **Start new build** → workflow **“iOS to TestFlight”** → **Start build**.
2. Codemagic auto-creates the signing certificate + provisioning profile, builds a
   signed `.ipa`, and uploads to TestFlight.
3. Wait for Apple to finish “Processing” (a few minutes; you'll get an email).

### 2f. Install on your iPhone
1. Install **TestFlight** from the App Store on your iPhone.
2. Sign in with the **same Apple ID**. The **OnAir** build appears → **Install**.
3. Drive to the car and test every control against the Android app. Keep the car
   safely supported for the first run.

---

## If you want to change the bundle ID or app name
Keep these three in sync:
- `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER`
- `codemagic.yaml` → `ios_signing.bundle_identifier`
- the App ID / app record in App Store Connect

After editing, commit & push (`git add -A && git commit -m "..." && git push`) and
Codemagic rebuilds.

---

## Going fully public later
Once TestFlight looks good, the same signed build submits to the **App Store**
(Codemagic can do `submit_to_app_store: true`). That's the free-to-everyone
distribution — I can set that workflow up when you're ready.
