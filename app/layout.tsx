import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Opsys Pro Property Management System",
  description: "Property, unit and tenant lifecycle management.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}