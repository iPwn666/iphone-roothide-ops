import type { Metadata, Viewport } from "next";
import { JetBrains_Mono, Manrope } from "next/font/google";

import "./globals.css";

const sans = Manrope({
  subsets: ["latin"],
  variable: "--font-sans",
});

const mono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: "TopOps AI",
  description: "iPhone-first AI cockpit that blends OpenAI and Gemini behind a native-like web experience.",
  applicationName: "TopOps AI",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "TopOps AI",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
  themeColor: "#eef4ff",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${sans.variable} ${mono.variable}`}>{children}</body>
    </html>
  );
}
