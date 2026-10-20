/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        canvas: {
          DEFAULT: 'var(--bg-canvas)',
          elevated: 'var(--bg-surface-elevated)',
          secondary: 'var(--bg-surface-secondary)',
          glass: 'var(--bg-glass)',
        },
        ink: {
          primary: 'var(--text-primary)',
          muted: 'var(--text-muted)',
          subtle: 'var(--text-subtle)',
        },
        accent: {
          primary: 'var(--accent-primary)',
          hover: 'var(--accent-hover)',
          subtle: 'var(--accent-subtle)',
        },
        border: {
          subtle: 'var(--border-subtle)',
          highlight: 'var(--border-highlight)',
        }
      },
      fontFamily: {
        vazir: ['Vazirmatn', 'IRANSansX', 'system-ui', 'sans-serif'],
        sans: ['Inter', 'SF Pro Display', 'Helvetica Neue', 'Vazirmatn', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      borderRadius: {
        'precision': '4px',
        'precision-md': '6px',
        'squircle-lg': '16px',
        'squircle-sheet': '24px',
      },
      boxShadow: {
        'glass': '0 8px 32px 0 rgba(0, 0, 0, 0.37)',
        'needle': '0 0 10px 2px rgba(255, 71, 0, 0.65)',
        'subtle-elevation': '0 2px 10px rgba(0,0,0,0.2)',
      },
      spacing: {
        '0.5': '2px',
        '1': '4px',
        '2': '8px',
        '3': '12px',
        '4': '16px',
        '5': '20px',
        '6': '24px',
        '7': '28px',
        '8': '32px',
        '10': '40px',
        '12': '48px',
        '16': '64px',
      }
    },
  },
  plugins: [],
}
