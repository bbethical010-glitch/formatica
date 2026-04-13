# Google Stitch UI/UX Generator Prompt - Formatica Mobile Application

## APPLICATION OVERVIEW

**App Name:** Formatica  
**Version:** 2.0.0  
**Platform:** Mobile (Android & iOS)  
**Category:** File Conversion & Media Utility  
**Core Philosophy:** Privacy-first, on-device processing — no cloud required

Formatica is a comprehensive file conversion and media utility application that enables users to convert documents, process videos, extract audio, manipulate images, and perform PDF operations — all processed entirely on-device with zero data leaving the user's device. The app emphasizes privacy, speed, and offline capability while maintaining a professional, modern interface.

---

## COMPLETE FEATURE INVENTORY

### 1. DOCUMENT CONVERSION
- **Convert Document:** DOCX, ODT, HTML, TXT, RTF, EPUB, Markdown to PDF
- **Engine:** Bundled Pandoc WASM (runs locally in WebView)
- **Features:** Format selection, progress tracking, error handling
- **Output:** PDF files saved to `/Download/Formatica/Documents/`

### 2. IMAGE PROCESSING
- **Images to PDF:** Combine multiple images into single PDF
- **Supported Formats:** JPG, PNG, WEBP, GIF, BMP
- **Features:** Image selection, ordering, quality settings
- **Output:** PDF saved to `/Download/Formatica/PDFs/`

### 3. AUDIO EXTRACTION
- **Extract Audio:** Extract audio tracks from video files
- **Supported Formats:** MP3, AAC, WAV
- **Features:** Audio quality selection, progress tracking
- **Output:** Audio files saved to `/Download/Formatica/Audio/`

### 4. VIDEO CONVERSION
- **Convert Video:** Convert between video formats
- **Supported Formats:** MP4, MKV, MOV, AVI, WEBM, GIF
- **Features:** Format selection, quality presets (fast/slow)
- **Output:** Video files saved to `/Download/Formatica/Videos/`

### 5. VIDEO COMPRESSION
- **Compress Video:** Reduce video file size while maintaining quality
- **Features:** 
  - Resolution options (Original, 1080p, 720p, 480p)
  - Quality presets (High/Medium/Low)
  - Real-time compression progress
  - Size reduction percentage display
- **Output:** Compressed video saved to `/Download/Formatica/Videos/`

### 6. IMAGE CONVERSION
- **Convert Image:** Convert between image formats
- **Supported Formats:** JPG, PNG, WEBP, GIF, BMP
- **Features:** Format selection, quality settings
- **Output:** Converted images saved to `/Download/Formatica/Images/`

### 7. PDF OPERATIONS
- **Merge PDF:** Combine multiple PDF files into one
  - Drag-and-drop reordering
  - File size display
  - Preserves original page sizes and layouts
  - Output: `/Download/Formatica/PDFs/`

- **Split PDF:** Extract specific page ranges from PDF
  - Page range selection (start/end page)
  - Page count validation
  - Preserves original page dimensions
  - Output: `/Download/Formatica/PDFs/`

- **Greyscale PDF:** Convert color PDFs to black & white
  - High-quality rasterization (300 DPI)
  - Preserves page layouts
  - Output: `/Download/Formatica/PDFs/`

### 8. TASK MANAGEMENT
- **Real-time Progress Tracking:** Visual progress indicators for all operations
- **Task History:** Complete log of all conversions
- **Active Tasks:** Shows currently processing operations
- **Completed Tasks:** Shows successful/failed operations with timestamps
- **Quick Actions:** Open file, Show in Folder (with file highlighting)

### 9. FILE MANAGEMENT
- **Show in Folder:** Opens file manager with output file highlighted/selected
- **Open File:** Opens file with default system app
- **Storage Management:** 
  - Displays total storage used
  - One-click clear all output files
  - Folder structure visualization
- **Output Organization:** Automatic categorization by file type:
  - `/Download/Formatica/Documents/` - Converted documents
  - `/Download/Formatica/PDFs/` - PDF operations
  - `/Download/Formatica/Audio/` - Extracted audio
  - `/Download/Formatica/Videos/` - Video conversions
  - `/Download/Formatica/Images/` - Converted images

### 10. SETTINGS & PREFERENCES
- **Theme Toggle:** Dark/Light mode with persistence
- **Storage Info:** Real-time storage usage calculation
- **Clear Storage:** Delete all output files with confirmation
- **App Info:** Version number, feature count
- **Privacy Info:** On-device processing confirmation

### 11. NAVIGATION & UI COMPONENTS
- **Home Screen:** Grid of all tools with category colors
- **History Screen:** Task log with active/completed sections
- **Settings Screen:** App preferences and storage management
- **Task Monitor Overlay:** Persistent task progress indicator
- **On-Device Status Ribbon:** Privacy indicator banner

---

## UI/UX DESIGN REQUIREMENTS

### 1. DESIGN PHILOSOPHY
Create a **high-class, professional, and visually distinctive** interface that embodies:
- **Premium Quality:** Feels like a paid, professional tool
- **Unique Identity:** Stands out from generic file converter apps
- **Elegant Refinement:** Sophisticated without being complex
- **Clean Minimalism:** No clutter, purposeful design only
- **Privacy-Forward:** Visual cues that reinforce on-device processing

### 2. COLOR SYSTEM

#### Dark Mode (Primary):
- **Background:** Deep, rich dark (#0F0F0F to #1A1A1A range)
- **Cards/Surfaces:** Elevated dark tones with subtle borders
- **Primary Brand:** Indigo (#4F46E5) — trust, technology
- **Success/Complete:** Teal (#0D9488) — accomplishment
- **Audio/Warning:** Rose (#E11D48) — energy, attention
- **Video:** Purple (#7C3AED) — creativity
- **Images:** Cyan (#0891B2) — clarity
- **Compression:** Orange (#EA580C) — transformation
- **Text Primary:** Light gray (#EFEFEF) — readability
- **Text Secondary:** Medium gray (#888888) — hierarchy

#### Light Mode (Secondary):
- **Background:** Warm, soft off-white (#F5F3EF)
- **Cards/Surfaces:** Pure white (#FFFFFF) with subtle shadows
- **Primary Brand:** Same indigo (#4F46E5) for consistency
- **All accent colors:** Maintain same hex values for brand consistency
- **Text Primary:** Near black (#1A1A1A) — contrast
- **Text Secondary:** Dark gray (#666666) — hierarchy

#### Color Application Rules:
- Each tool category has a distinct, recognizable color
- Colors are used sparingly for icons, buttons, and status indicators
- Maintain WCAG AA contrast ratios minimum
- Colors should feel cohesive, not rainbow-like

### 3. TYPOGRAPHY
- **Font Family:** Modern sans-serif (Inter, SF Pro, or similar)
- **Page Titles:** Bold, tight letter-spacing, clear hierarchy
- **Feature Titles:** Semi-bold, readable at a glance
- **Body Text:** Regular weight, generous line-height (1.4+)
- **Captions/Labels:** Smaller, lighter weight, muted colors
- **Numbers/Stats:** Monospace or tabular figures for alignment

### 4. LAYOUT STRUCTURE

#### Home Screen:
- **Header:** App logo, title, tagline, action buttons (History, Theme, Settings)
- **Status Ribbon:** Prominent "All tools run on-device" privacy indicator
- **Tools Grid:** 9 feature cards in clean list format
  - Each card: Icon (colored background), Title, Subtitle, Chevron
  - Spacing: Consistent 8px gaps between cards
  - Cards: Rounded corners (14px), subtle borders
- **Recent Activity:** Last 5 completed tasks with status icons

#### Tool Screens (Universal Pattern):
- **AppBar:** Back button, Title, Info icon
- **Privacy Banner:** "Processed entirely on-device — no internet required"
- **Input Section:** File picker area with clear call-to-action
- **Configuration:** Settings/options specific to tool
- **Action Button:** Prominent, colored, with icon
- **Progress Area:** Animated progress bar, percentage, status text
- **Result Card:** Success/failure state with action buttons
  - "Open File" button
  - "Show in Folder" button (with file highlighting)

#### History Screen:
- **AppBar:** Title, "Clear All" button (when tasks exist)
- **Empty State:** Icon, title, subtitle (centered, muted)
- **Active Tasks Section:** Progress indicators, running status
- **Completed Tasks Section:** Status icons, timestamps, action buttons

#### Settings Screen:
- **Sectioned Layout:** Grouped by category
- **Cards:** Icon, Title, Subtitle, Toggle/Action
- **Sections:**
  - Appearance (Theme toggle)
  - Document Engine (Pandoc info)
  - Output Location (Folder structure, Quick open)
  - Storage (Usage, Clear button)
  - About (Version, Privacy info)

### 5. COMPONENTS DESIGN

#### Cards:
- Border radius: 12-14px
- Subtle borders (1px) in dark mode
- Soft shadows in light mode
- Consistent padding (14-16px)
- Hover/press states with subtle elevation change

#### Buttons:
- **Primary:** Filled, colored, rounded (8-10px)
- **Secondary:** Outlined, subtle border
- **Tertiary:** Text-only, colored
- **Mini Buttons:** Compact, with icon + label, for action rows
- All buttons: Press animation (scale 0.98 or ripple)

#### Progress Indicators:
- Linear progress bars: 4px height, rounded
- Colored track with brand color
- Percentage text overlay
- Smooth, continuous animation (not stepped)

#### File Picker Areas:
- Large, tappable zones
- Dashed borders or subtle backgrounds
- Clear iconography
- "Tap to Add" text with format info
- Drag handles for reordering (merge/split screens)

#### Status Badges:
- Success: Green/teal checkmark icon
- Failed: Rose/error icon
- Running: Spinning sync icon + percentage
- Queued: Clock icon
- Compact, inline with text

---

## ANIMATIONS & INTERACTIONS

### 1. ANIMATION PHILOSOPHY
- **Ultra-smooth transitions:** 60fps, no jank
- **Liquid glass style:** Fluid, organic motion (macOS/iOS inspired)
- **Purposeful:** Every animation serves a function
- **Subtle:** Enhances, never distracts
- **Consistent:** Same timing curves throughout app

### 2. SPECIFIC ANIMATIONS REQUIRED

#### Page Transitions:
- **Slide + Fade:** New pages slide in from right with slight fade (250ms)
- **Shared Element:** File cards animate between screens when tapped
- **Spring Physics:** Bouncy, natural motion (not linear)
- **Parallax:** Subtle depth on scroll (header shrinks slightly)

#### List Animations:
- **Staggered Entry:** Cards fade in sequentially (50ms delay each)
- **Scroll Reveal:** Cards animate as they enter viewport
- **Reorder Animation:** Smooth drag-and-drop with ghost element
- **Delete Animation:** Swipe to dismiss with slide-out + fade

#### Button Interactions:
- **Press:** Scale down to 0.98 with subtle shadow change
- **Ripple:** Material-style ripple effect on touch
- **Loading State:** Button content replaced with spinner, maintains size
- **Success State:** Morph to checkmark with green pulse

#### Progress Animations:
- **Progress Bar:** Smooth, continuous fill (not stepped)
- **Percentage Counter:** Animated number roll-up
- **Completion:** Progress bar morphs to success state with pulse
- **Failure:** Shake animation + red flash

#### File Card Animations:
- **Hover (Web):** Slight lift (2px) + shadow increase
- **Press:** Scale 0.98, background darken slightly
- **Selection:** Border color change + subtle glow
- **Drag:** Elevation increase, slight rotation based on drag position

#### Theme Transition:
- **Smooth Cross-fade:** Colors transition over 300ms
- **Icon Animation:** Sun/moon morph or rotate during toggle
- **Card Transition:** Background color smoothly shifts

#### Micro-interactions:
- **Pull to Refresh:** Elastic overscroll with bounce
- **Toast/Snackbar:** Slide up from bottom with spring
- **Dialog:** Scale from 0.9 to 1.0 with fade
- **Tab Switch:** Indicator slides with spring physics
- **Toggle Switch:** Smooth slide with color transition

#### Loading States:
- **Skeleton Screens:** Shimmer animation on placeholder cards
- **Spinners:** Custom designed, not default system spinner
- **Progressive Loading:** Content appears as it loads (not all at once)

### 3. ANIMATION TIMING CURVES
- **Entrance:** `easeOutQuint` or `spring(0.4, 0.8)` — fast out, slow in
- **Exit:** `easeInQuint` — slow out
- **Continuous:** `linear` or `easeInOut` for loops
- **Interactive:** `spring(0.3, 0.7)` — responsive, snappy
- **Page Transitions:** `easeInOutCubic` — smooth, balanced

### 4. LIQUID GLASS EFFECTS
- **Frosted Glass:** Blur + transparency on overlays (Settings, Dialogs)
- **Reflection:** Subtle light reflection on cards when tilted (gyroscope)
- **Fluid Motion:** Cards "float" slightly on scroll with parallax
- **Organic Shapes:** Rounded corners, soft edges everywhere
- **Gradient Overlays:** Subtle gradients on headers, not flat colors

---

## THEME TOGGLE DESIGN (SPECIAL REQUIREMENT)

### Custom Animated Theme Switcher

Design a **premium, custom dark/light mode toggle** with:

#### Visual Elements:
- **Dark Mode Icon:** Stylized crescent moon with stars
- **Light Mode Icon:** Radiant sun with rays
- **Track:** Pill-shaped, gradient background
- **Thumb:** Circular, contains the icon

#### Animation Sequence (On Toggle):
1. **Moon Transform:** Crescent moon rotates and morphs into sun
2. **Stars Fade:** Small stars fade out as sun appears
3. **Sun Rays:** Sun rays animate outward with spring physics
4. **Background:** Track gradient shifts from dark blue to warm yellow
5. **Thumb:** Slides smoothly with slight overshoot (spring)
6. **Global:** All app colors cross-fade over 300ms

#### Interaction:
- **Tap:** Triggers full animation sequence
- **Hold:** Preview effect (icons pulse slightly)
- **Haptic:** Subtle vibration on toggle (Android)

#### Placement:
- **Home Screen:** Top-right corner, in header row
- **Settings Screen:** First item in Appearance section
- **Size:** 48x48dp minimum for accessibility

---

## ADDITIONAL UI ENHANCEMENTS

### 1. ON-DEVICE PRIVACY INDICATOR
Design a **prominent, reassuring privacy banner** that appears:
- **Home Screen:** Below header, full-width ribbon
- **Tool Screens:** Below AppBar, before content
- **Design:**
  - Background: Success color with 10-15% opacity
  - Border: Solid success color
  - Icon: Lightning bolt or shield
  - Text: "⚡ All tools run on-device — no internet required"
  - Subtle pulse animation on load (once)

### 2. TASK MONITOR OVERLAY
Persistent overlay showing active conversions:
- **Position:** Bottom of screen, above navigation
- **Design:** 
  - Compact card with progress bar
  - Task label (truncated)
  - Percentage + spinning icon
  - Tap to expand (shows all active tasks)
- **Animation:** Slides up when task starts, slides down when complete
- **Behavior:** Non-blocking, user can navigate freely

### 3. FILE MANAGER INTEGRATION UI
When "Show in Folder" is tapped:
- **Transition:** Smooth fade to system file manager
- **Feedback:** Brief loading indicator during handoff
- **Success:** No additional UI (system handles it)
- **Error:** Toast message with exact path as fallback

### 4. EMPTY STATES
Design **friendly, helpful empty states** for:
- **No History:** Large icon, encouraging text, CTA to start first conversion
- **No Files Selected:** Illustration, "Tap to Add" prompt, format list
- **Search No Results:** Magnifying glass, "No matches found", clear search button
- **Offline (if applicable):** Cloud with slash, "Works offline!" reassurance

### 5. ERROR STATES
Design **clear, actionable error displays**:
- **Conversion Failed:** 
  - Red rose icon
  - Error message (truncated, expandable)
  - "Retry" button
  - "View Logs" option (if applicable)
- **Permission Denied:** 
  - Shield icon
  - Clear explanation
  - "Open Settings" button
  - Step-by-step guide
- **Storage Full:** 
  - Storage icon with warning
  - Current usage / available
  - "Clear Storage" quick action

### 6. CONFIRMATION DIALOGS
Design **clean, modern dialogs** for:
- **Clear Storage:** 
  - Warning icon (rose color)
  - Clear explanation of consequences
  - "Cancel" / "Delete All" buttons
  - Red destructive action button
- **Clear History:** 
  - Info icon
  - Simple question
  - "Cancel" / "Clear" buttons
- **Exit During Conversion:** 
  - Warning: "Conversion in progress"
  - "Continue" / "Cancel" options

### 7. SUCCESS STATES
Design **satisfying completion feedback**:
- **Success Card:**
  - Large green/teal checkmark (animated scale-in)
  - "Success" or "Complete" title
  - File name and size
  - "Open File" and "Show in Folder" buttons
  - Subtle confetti or particle burst (optional, tasteful)
- **Progress Completion:**
  - Progress bar smoothly transitions to 100%
  - Color shifts to success teal
  - Checkmark appears with pulse
  - Success card slides up

---

## SCREEN-BY-SCREEN SPECIFICATIONS

### SCREEN 1: HOME
**Layout:**
- Header: Logo (36x36, indigo background, "F" text), Title, Tagline, 3 icon buttons
- Status Ribbon: Full-width, success color theme
- Section Label: "TOOLS" in uppercase, muted
- Tool Cards: 9 cards in vertical list, 8px gap between pairs
- Recent Activity: Section label, up to 5 task items

**Interactions:**
- Card tap: Navigate to tool screen (slide transition)
- History icon: Navigate to history screen
- Theme icon: Toggle theme (with animation)
- Settings icon: Navigate to settings screen
- Recent task tap: Open file

**Responsive:**
- Tablet: 2-column grid for tool cards
- Landscape: Header condenses, cards remain single column

---

### SCREEN 2: CONVERT DOCUMENT
**Layout:**
- AppBar: Back, "Convert Document", Info icon
- Privacy Banner: On-device indicator
- Input Area: Large card with PDF icon, "Tap to Add Document", format list
- Format Selector: Dropdown or segmented control (DOCX, ODT, HTML, TXT, RTF, EPUB, MD)
- Convert Button: Full-width, indigo, "Convert to PDF"
- Progress Area: (When active) Progress bar, percentage, status text
- Result Card: (When complete) Success state with actions

**Flow:**
1. User taps input area → File picker opens
2. User selects file → File name appears in input area
3. User taps "Convert to PDF" → Progress starts
4. Progress completes → Result card appears with Open/Show in Folder buttons

---

### SCREEN 3: IMAGES TO PDF
**Layout:**
- Similar to Convert Document
- Input Area: "Tap to Add Images", multi-select enabled
- Image List: Thumbnails with drag handles for reordering
- Convert Button: "Create PDF"

**Special:**
- Drag-and-drop reordering
- Image count badge
- Total size display

---

### SCREEN 4: EXTRACT AUDIO
**Layout:**
- Input Area: "Tap to Select Video"
- Format Selector: MP3, AAC, WAV options
- Quality Selector: High/Medium/Low bitrate
- Extract Button: "Extract Audio"

---

### SCREEN 5: CONVERT VIDEO
**Layout:**
- Input Area: "Tap to Select Video"
- Format Selector: MP4, MKV, MOV, AVI, WEBM, GIF
- Quality Presets: Fast (ultrafast) / Slow (superfast)
- Convert Button: "Convert Video"

---

### SCREEN 6: COMPRESS VIDEO
**Layout:**
- Input Area: "Tap to Select Video"
- Original Size Display: File size in MB
- Resolution Selector: Original, 1080p, 720p, 480p
- Quality Presets: High, Medium, Low
- Estimated Size: Dynamic calculation based on settings
- Compress Button: "Compress Video"

**Special:**
- Side-by-side comparison (original vs compressed size)
- Percentage reduction display after compression

---

### SCREEN 7: CONVERT IMAGE
**Layout:**
- Input Area: "Tap to Select Image"
- Format Selector: JPG, PNG, WEBP, GIF, BMP
- Quality Slider: For lossy formats (JPG, WEBP)
- Convert Button: "Convert Image"

---

### SCREEN 8: MERGE PDF
**Layout:**
- Input Area: "Tap to Add PDFs" (multi-select)
- File List: 
  - Each item: PDF icon, file name, file size, delete button, drag handle
  - Drag to reorder
- Merge Button: "Merge PDFs"
- Result: Merged file name, size, Open/Show in Folder buttons

**Special:**
- Minimum 2 PDFs required
- Reorder animation smooth
- File count badge

---

### SCREEN 9: SPLIT PDF
**Layout:**
- Input Area: "Tap to Select PDF"
- Page Info: "Total Pages: X"
- Range Selector: 
  - Start Page: Number input
  - End Page: Number input
  - Validation: Start < End, End <= Total
- Split Button: "Split PDF"
- Result: Split file name, page range, size, actions

**Special:**
- Page preview thumbnails (optional)
- Smart validation (auto-correct invalid ranges)

---

### SCREEN 10: GREYSCALE PDF
**Layout:**
- Input Area: "Tap to Select PDF"
- Info Card: "Converts all colors to black & white at 300 DPI"
- Convert Button: "Convert to Greyscale"
- Result: Greyscale file name, size, actions

---

### SCREEN 11: HISTORY
**Layout:**
- AppBar: "Recent Activity", "Clear All" (conditional)
- Empty State: (If no tasks) Centered icon + text
- Active Section: "ACTIVE" label, running tasks with progress
- Completed Section: "COMPLETED" label, finished tasks newest-first

**Task Item:**
- Status icon (check/error/sync/clock)
- Task label (truncated)
- Status text (Complete/Failed/XX%/Queued)
- Progress bar (if running)
- Error message (if failed, expandable)
- Action buttons: Open, Show in Folder (if successful)

---

### SCREEN 12: SETTINGS
**Layout:**
- AppBar: "Settings"
- Sections:
  - **Appearance:** Dark Mode toggle (custom animated switcher)
  - **Document Engine:** Bundled Pandoc info, First Launch Warm-up note
  - **Output Location:** 
    - Folder path with "Open" button
    - Folder structure visualization (5 subfolders)
  - **Storage:** 
    - Storage used (calculated)
    - "Clear" button (rose color)
  - **About:** Version, feature count, Privacy statement

**Folder Structure Card:**
- Lists all 5 subfolders with descriptions
- Clean, monospace-style paths
- Compact layout

---

## TECHNICAL CONSTRAINTS & LIMITATIONS

### 1. PLATFORM LIMITATIONS
- **Android 10+ Scoped Storage:** Files saved to public Downloads only
- **File Highlighting:** Depends on file manager app support (varying)
- **On-Device Processing:** Requires sufficient device storage and RAM
- **Pandoc WASM:** First launch warm-up (5-10 seconds)

### 2. UI LIMITATIONS
- **Custom Theme Toggle:** Requires custom animation, not native switch
- **File Manager Integration:** Cannot control external app behavior
- **Progress Tracking:** Limited to what FFmpeg/Pandoc APIs expose
- **Image Thumbnails:** Memory-intensive for large PDFs

### 3. PERFORMANCE CONSIDERATIONS
- **Animations:** Must maintain 60fps, avoid heavy blur on low-end devices
- **File Lists:** Virtualize long lists (history can grow large)
- **Image Processing:** Show loading states during heavy operations
- **Progress Updates:** Throttle to 10-20 updates per second max

---

## DESIGN DELIVERABLES EXPECTED

Generate a complete UI/UX design including:

### 1. SCREEN DESIGNS (12 Screens)
- Home Screen (Dark + Light mode)
- Convert Document (Dark + Light mode)
- Images to PDF (Dark + Light mode)
- Extract Audio (Dark + Light mode)
- Convert Video (Dark + Light mode)
- Compress Video (Dark + Light mode)
- Convert Image (Dark + Light mode)
- Merge PDF (Dark + Light mode)
- Split PDF (Dark + Light mode)
- Greyscale PDF (Dark + Light mode)
- History Screen (Dark + Light mode)
- Settings Screen (Dark + Light mode)

### 2. COMPONENT LIBRARY
- Buttons (Primary, Secondary, Tertiary, Mini)
- Cards (Feature, Task, Settings, Result)
- Inputs (File picker, Dropdown, Number input)
- Progress indicators
- Status badges
- Dialogs (Alert, Confirmation)
- Empty states
- Error states
- Success states

### 3. ANIMATION SPECIFICATIONS
- Page transitions
- List animations
- Button interactions
- Progress animations
- Theme toggle animation (detailed sequence)
- Micro-interactions
- Loading states

### 4. DESIGN SYSTEM DOCUMENTATION
- Color palette (Dark + Light)
- Typography scale
- Spacing system (4px grid)
- Border radius values
- Shadow/elevation system
- Icon style guide
- Layout grid (mobile + tablet)

### 5. INTERACTIVE PROTOTYPE
- Clickable flow from Home → Tool → Result
- Theme toggle demonstration
- Task progress simulation
- File selection flow
- Error state triggers

---

## QUALITY STANDARDS

### Must Achieve:
✅ Premium, professional appearance (not amateur or generic)  
✅ Unique visual identity (recognizable as Formatica)  
✅ Elegant and refined (sophisticated, not flashy)  
✅ Clean and minimal (no unnecessary elements)  
✅ Consistent across all screens and states  
✅ Accessible (WCAG AA minimum, proper contrast)  
✅ Responsive (works on phones and tablets)  
✅ Fluid animations (60fps, smooth, purposeful)  
✅ Intuitive navigation (user never lost)  
✅ Clear feedback (user always knows what's happening)  

### Must Avoid:
❌ Cluttered or busy layouts  
❌ Inconsistent spacing or alignment  
❌ Poor color contrast  
❌ Generic Material Design look  
❌ Overly complex animations  
❌ Confusing navigation  
❌ Missing states (empty, error, loading)  
❌ Inaccessible elements  
❌ Platform-inconsistent patterns  
❌ Exposing technical implementation details  

---

## FINAL NOTES

### Brand Personality:
- **Trustworthy:** Privacy-first, transparent processing
- **Professional:** Clean, polished, reliable
- **Modern:** Current design trends, not dated
- **Approachable:** Friendly, not intimidating
- **Efficient:** Fast, streamlined, no friction

### Target Audience:
- Professionals needing quick file conversions
- Students working with documents and PDFs
- Content creators processing media files
- Privacy-conscious users avoiding cloud services
- Anyone needing offline file manipulation tools

### Competitive Differentiation:
- **Privacy:** 100% on-device, no data leaves device
- **Speed:** No upload/download wait times
- **Offline:** Works without internet connection
- **Comprehensive:** 9 tools in one app
- **Free:** No subscriptions, no hidden costs

### Success Metrics:
- User can complete a conversion in under 30 seconds
- Zero confusion about where files are saved
- Clear understanding of privacy benefits
- Delightful, smooth experience throughout
- Professional appearance that builds trust

---

**END OF PROMPT**

This prompt provides complete, detailed specifications for generating a professional, premium UI/UX design for the Formatica mobile application. All features, workflows, animations, and design requirements are comprehensively documented to ensure the generated design aligns perfectly with the application's functionality and brand identity.
