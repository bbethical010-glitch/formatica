# Formatica Studio: Android Design & Feature Requirements

This document outlines the core functional features and aesthetic requirements for the Formatica Android application, as defined by the **Formatica Studio Liquid Glass** design philosophy.

## 1. Aesthetic Vision: "Liquid Glass"
The application must adhere to a "Premium On-Device Laboratory" feel, utilizing high-end UI techniques:
- **Color Palette**: 
    - **Primary Base**: `#0B1326` (The Void)
    - **Accent Primaries**: `#5B4FE8` (Indigo), `#E8507C` (Rose), `#8B5CF6` (Purple).
    - **Surfaces**: Glassmorphism with `rgba(255, 255, 255, 0.07)` background and `28px` backdrop blur.
- **Typography**: **Manrope** (Variable). Used in an editorial hierarchy with heavy weights for labels and light weights for descriptions.
- **Atmosphere**: Deep mesh backgrounds with moving ambient light sources to simulate depth.

## 2. Core Features (The Studio)

### A. Document Processing
1.  **Universal Document Converter**: Support for DOCX, ODT, HTML to PDF conversion.
2.  **Images to PDF**: Batch process up to 50 images (JPG, PNG, WEBP) into a single A4 or "Fit to Page" PDF.
3.  **PDF Suite**:
    - **Merge**: Reorderable list of PDFs for concatenation.
    - **Split**: Page-level extraction or "Every N Pages" partitioning.
    - **Greyscale**: Color stripping for print optimization.

### B. Media Processing
1.  **Extract Audio (Vocalis Engine)**: Dual-stream isolation of audio from Video (MP4, MKV, MOV). Supports MP3/WAV/AAC at variable bitrates (128k-320k).
2.  **Video Compression**: Resolution-aware compression (CRF-based) to reduce footprint without visible quality loss.
3.  **Visual Conversion**: Cross-format conversion for both Video and Images.

## 3. Interaction Design Requirements

### Navigation & Layout
- **Signature Dock**: A floating, 240px wide glassy navigation pill at the bottom with high-vis runner animations.
- **Home Interface**:
    - **Global Search**: Real-time filtering of tools.
    - **Hybrid Grid**: Strategic mix of horizontal cards for major tools and aspect-square cards for secondary utilities.
    - **Status Chips**: Pulsing indicator for "On-Device Mode".

### Tool Workflow (The Sticky Bar)
Every processing tool must follow a consistent 3-stage flow anchored by a **Sticky Bottom Bar**:
1.  **CTA State**: Large, branded action button (e.g., "Extract Audio").
2.  **Processing State**: Inline progress indicator with percentage, indeterminate animations (Mesh pulses), and a "Cancel" option.
3.  **Done State**: Success confirmation with primary "Open File" and secondary "Share/Folder" actions.

## 4. Technical Requirements
- **Hardware Acceleration**: Use FFMPEG and Pandoc bridges for near-instant on-device processing.
- **Privacy First**: Zero cloud dependency. All metadata and file contents must remain on the local Android storage (`/Documents/Formatica`).
- **Performance**: Implement staggered animations (0.05s increments) for page transitions to maintain a "fluid" feel.

## 5. Screen Inventory
| Screen | Description | Key Elements |
| :--- | :--- | :--- |
| **Home** | Central hub | Search, Tool Grid, Navigation Dock |
| **History** | Task log | Status badges (Done/Fail), File paths |
| **Tool Detail** | Processing engine | Preview Zone, Options, Sticky Bar |
| **Settings** | Configuration | Theme Toggle, Default paths, Storage info |
