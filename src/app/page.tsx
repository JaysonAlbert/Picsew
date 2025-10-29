"use client";

import { useState, useRef } from "react";
import { processVideo as picsewProcessVideo } from "./picsew";

export default function HomePage() {
  const [log, setLog] = useState<string[]>([]);
  const [processing, setProcessing] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file && videoRef.current) {
      const url = URL.createObjectURL(file);
      videoRef.current.src = url;
      addLog(`Video '${file.name}' loaded.`);
    }
  };

  const addLog = (message: string) => {
    console.log(message);
    setLog((prev) => [...prev, message]);
  };

  const processVideo = async () => {
    addLog("Starting video processing...");
    setProcessing(true);

    if (videoRef.current) {
      await picsewProcessVideo(videoRef.current, addLog, canvasRef.current);
    }

    setProcessing(false);
    addLog("Video processing finished.");
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-900 text-white">
      <div className="container flex flex-col items-center justify-center gap-8 px-4 py-16">
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          Picsew - Scrolling Screenshot Stitcher
        </h1>
        
        <div className="w-full max-w-2xl">
          <div className="flex flex-col gap-4">
            <input type="file" accept="video/*" onChange={handleFileChange} className="rounded-lg bg-gray-800 p-2" />
            <button onClick={processVideo} disabled={processing} className="rounded-lg bg-blue-600 px-4 py-2 font-bold text-white hover:bg-blue-700 disabled:bg-gray-500">
              {processing ? "Processing..." : "Process Video"}
            </button>
          </div>
        </div>

        <div className="mt-8 w-full max-w-4xl">
          <h2 className="text-2xl font-bold">Output</h2>
          <canvas ref={canvasRef} className="mt-4 w-full rounded-lg bg-gray-800"></canvas>
        </div>

        <div className="mt-8 w-full max-w-4xl">
          <h2 className="text-2xl font-bold">Logs</h2>
          <div className="mt-4 h-48 overflow-y-auto rounded-lg bg-gray-800 p-4 font-mono text-sm">
            {log.map((line, index) => (
              <p key={index}>{`> ${line}`}</p>
            ))}
          </div>
        </div>

        <video ref={videoRef} className="hidden" />
      </div>
    </main>
  );
}
