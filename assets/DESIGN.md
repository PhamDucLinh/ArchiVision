---
name: Monolith Architectural AI
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c4c7c8'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c6c6c7'
  primary: '#ffffff'
  on-primary: '#2f3131'
  primary-container: '#e2e2e2'
  on-primary-container: '#636565'
  inverse-primary: '#5d5f5f'
  secondary: '#bcc7de'
  on-secondary: '#263143'
  secondary-container: '#3e495d'
  on-secondary-container: '#aeb9d0'
  tertiary: '#ffffff'
  on-tertiary: '#213145'
  tertiary-container: '#d3e4fe'
  on-tertiary-container: '#56657c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c7'
  on-primary-fixed: '#1a1c1c'
  on-primary-fixed-variant: '#454747'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#d3e4fe'
  tertiary-fixed-dim: '#b7c8e1'
  on-tertiary-fixed: '#0b1c30'
  on-tertiary-fixed-variant: '#38485d'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md-mobile:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.2'
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.08em
  mono-data:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.4'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
  panel-width: 320px
---

## Brand & Style

The brand identity centers on precision, structural integrity, and the intersection of human creativity with machine intelligence. The target audience includes architects, interior designers, and 3D artists who require a tool that feels as professional and intentional as the blueprints they produce.

The design style is **Corporate Modern with Technical Minimalism**. It utilizes a sophisticated dark-mode environment to allow high-fidelity architectural renders to take center stage. The aesthetic mimics high-end CAD software and architectural portfolios: clean lines, generous whitespace (balanced against dark surfaces), and a restrained use of color. The emotional response should be one of calm, focused authority and cutting-edge technological capability.

## Colors

The palette is engineered for high-contrast legibility and deep focus.
- **Primary Background (#121212):** A deep, neutral black used for the main application canvas to maximize the "pop" of rendered images.
- **Surface/Card (#1A1A1A):** A slight elevation from the background used for panels, sidebars, and input containers.
- **Primary Action (#FFFFFF):** Used for critical CTAs and primary icons. This high-contrast white denotes "Compute" or "Finalize" actions.
- **Accent Navy (#1E293B):** Used for selection states, subtle highlights, and secondary interactive elements to provide a professional, "blueprint" undertone.
- **Muted Grays (#64748B):** Reserved for labels, metadata, and non-essential descriptors to maintain visual hierarchy.

## Typography

The system utilizes **Inter** for its neutral, highly legible characteristics, ensuring the UI does not compete with the architectural content. A secondary monospace font, **JetBrains Mono**, is introduced for technical data, dimensions, and AI processing strings to reinforce the "high-tech" architectural feel.

- **Headlines:** Bold and tight-set to act as structural anchors.
- **Labels:** Small-caps are used for section headers in sidebars to mimic architectural notations.
- **Body:** Standardized at 14px/16px for optimal readability against dark backgrounds.
- **Text Alignment:** Strict adherence to grid lines; avoid center alignment for technical lists.

## Layout & Spacing

The layout follows a **Fixed-Sidebar Fluid-Canvas** model. The primary workspace (the viewport) expands to fill the remaining screen real estate, while control panels remain at fixed widths (320px) to ensure consistency in complex toolsets.

- **Grid:** A 12-column grid is used for dashboard views, while tool-heavy views use a modular layout based on a 4px baseline unit.
- **Safe Areas:** Maintain a 32px margin from the screen edge on desktop to prevent the UI from feeling cramped.
- **Breakpoints:**
  - **Mobile (<768px):** Sidebars collapse into a bottom drawer or full-screen overlay.
  - **Desktop (>1024px):** Dual-panel layout (Layer/Asset panel on left, Property/Settings panel on right).

## Elevation & Depth

In this dark-mode system, depth is communicated through **Tonal Layering** and **Subtle Outlines** rather than heavy shadows.

- **Base Layer (#121212):** The canvas.
- **Raised Layer (#1A1A1A):** Floating panels and cards. These should have a 1px solid border (#2D2D2D) to define their edges against the dark background.
- **Active State:** Elements being dragged or high-priority modals use a very subtle, soft ambient shadow (Black, 40% opacity, 20px blur) to appear "lifted."
- **Glassmorphism:** Use a 12px backdrop blur on top-level navigation bars to allow the architectural renders to partially bleed through, creating a sense of immersion.

## Shapes

The shape language balances modern software trends with architectural rigidity. 
- **Standard Radius:** 8px (0.5rem) for buttons, inputs, and small cards.
- **Large Radius:** 16px (1rem) for main image viewports and prominent containers.
- **Dashed Borders:** Upload zones and "empty state" slots utilize a 1px dashed stroke with a 4px gap, signaling a "placeholder" or "blueprint" area awaiting content.

## Components

### Buttons
- **Primary:** Solid White background, Black text. 8px radius. High-impact.
- **Secondary:** Accent Navy (#1E293B) background, White text.
- **Ghost:** No background, 1px border (#2D2D2D). Used for low-priority actions.

### Inputs & Fields
- **Text Fields:** Surface background (#1A1A1A), 8px radius, subtle 1px border. Focus state uses a 1px White border.
- **Labels:** Positioned above the input, using `label-caps` in Muted Gray (#64748B).

### Cards
- Used for project previews and AI style presets. 
- Must include a 1px internal border to ensure separation. 
- Titles should be left-aligned with `body-sm` bold.

### Upload Zones
- Large containers with #1A1A1A background and a dashed border (#64748B). 
- Icons within these zones should be thin-stroke (1.5px) for a technical look.

### Process Indicators
- Use a monochromatic loading bar (White on Dark Gray) to maintain the professional, understated aesthetic. Avoid "playful" animations.