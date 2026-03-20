import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "TopOps AI",
    short_name: "TopOps AI",
    description: "An iPhone-first AI cockpit for OpenAI and Gemini.",
    display: "standalone",
    start_url: "/",
    background_color: "#eef4ff",
    theme_color: "#eef4ff",
    orientation: "portrait",
  };
}
