import React, { useEffect, useState } from "react";
import clsx from "clsx";
import type { Props } from "@theme/NotFound/Content";
import Rive from "@rive-app/react-canvas";
import { useLocation } from "@docusaurus/router";

export default function NotFoundContent({ className }: Props): JSX.Element {
  const location = useLocation();
  const [suggestedPath, setSuggestedPath] = useState<string | null>(null);

  useEffect(() => {
    // Try to extract version from URL when hitting a 404
    const pathParts = location.pathname.split("/");
    if (pathParts.length > 1) {
      // Check if the first segment looks like a version number
      const possibleVersion = pathParts[1];
      if (/^\d+\.\d+\.\d+$/.test(possibleVersion)) {
        // This might be a version path that doesn't exist
        setSuggestedPath(`/${possibleVersion}/docs/home`);
      } else {
        // Default to the main docs
        setSuggestedPath("/docs/home");
      }
    }
  }, [location.pathname]);

  return (
    <main
      className={clsx(
        "container mx-auto flex flex-col items-center justify-center min-h-screen text-center",
        className
      )}
    >
      <div className="flex flex-col lg:flex-row items-center justify-center w-full lg:max-w-5xl spacing-x-12">
        <div className="w-full h-full flex justify-center">
          <Rive
            className="w-full h-full aspect-[1644.16/1000]"
            src={require("@site/static/rive/robot.riv").default}
            stateMachines="State Machine 1"
          />
        </div>
        <div className="w-full md:w-2/3 text-left spacing-y-6">
          <h1 className="text-6xl font-bold">404</h1>
          <h2 className="text-3xl">UH OH! You're lost.</h2>
          <p className="text-lg text-gray-500 dark:text-gray-400">
            We apologize, but the page you are trying to access cannot be found.
            <br></br> Please check the URL for errors or use the button below to
            return to the homepage.
            <br></br>If you believe this is an error, please create a question
            in our <a href="https://discord.gg/gs5QYhfv9x">Discord</a>.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 mt-4">
            <a href="/">
              <button className="button px-6 py-3 text-lg font-bold text-white bg-[#2ca1cc] rounded-lg hover:bg-[#227c9d] border-[#227c9d] duration-200 transition">
                Go Home
              </button>
            </a>
            {suggestedPath && (
              <a href={suggestedPath}>
                <button className="button px-6 py-3 text-lg font-bold text-white bg-[#15b0a0] rounded-lg hover:bg-[#139e90] border-[#139e90] duration-200 transition">
                  Go to Documentation
                </button>
              </a>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
