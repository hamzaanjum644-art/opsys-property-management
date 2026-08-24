import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Opsys Pro Property Management System",
  description: "Properties, units, tenants and documents in one connected record.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}