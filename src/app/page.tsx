"use client";

import { useState, useRef } from "react";
import { processVideo as picsewProcessVideo } from "./picsew";

export default function HomePage() {
  const [step, setStep] = useState("upload"); // upload, processing, result
  const [progress, setProgress] = useState(0);
  const [fileName, setFileName] = useState("");
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file && videoRef.current) {
      const url = URL.createObjectURL(file);
      videoRef.current.src = url;
      setFileName(file.name);
      setStep("processing");
    }
  };

  const handleUploadClick = () => {
    fileInputRef.current?.click();
  };

  const processVideo = async () => {
    setStep("processing");
    setProgress(0);

    if (videoRef.current && canvasRef.current) {
      await picsewProcessVideo(
        videoRef.current,
        () => {},
        canvasRef.current,
        (p) => setProgress(Math.round(p))
      );
    }

    setStep("result");
  };

  const handleDownload = () => {
    if (canvasRef.current) {
      const link = document.createElement("a");
      link.download = "stitched_screenshot.png";
      link.href = canvasRef.current.toDataURL("image/png");
      link.click();
    }
  };

  const handleRestart = () => {
    setStep("upload");
    setProgress(0);
    setFileName("");
    if (videoRef.current) {
      videoRef.current.src = "";
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-900 text-white p-4 transition-all duration-500 ease-in-out">
      <div className="w-full max-w-md text-center">
        <h1 className="text-4xl font-bold tracking-tight mb-2">
          Picsew
        </h1>
        <p className="text-lg text-gray-400 mb-8">
          Stitch scrolling screenshots from a video.
        </p>

        {step === "upload" && (
          <div className="flex flex-col items-center justify-center">
            <input
              type="file"
              accept="video/*"
              onChange={handleFileChange}
              ref={fileInputRef}
              className="hidden"
            />
            <button
              onClick={handleUploadClick}
              className="w-full max-w-xs rounded-full bg-blue-600 px-8 py-4 font-bold text-white text-lg hover:bg-blue-700 transition-transform duration-300 ease-in-out transform hover:scale-105"
            >
              Select Video
            </button>
          </div>
        )}

        {step === "processing" && !progress && (
            <div className="flex flex-col items-center justify-center">
                <p className="text-gray-300 mb-4">{fileName}</p>
                <button
                onClick={processVideo}
                className="w-full max-w-xs rounded-full bg-green-600 px-8 py-4 font-bold text-white text-lg hover:bg-green-700 transition-transform duration-300 ease-in-out transform hover:scale-105"
                >
                Process Video
                </button>
            </div>
        )}

        {step === "processing" && progress > 0 && (
          <div className="flex flex-col items-center justify-center">
            <div className="relative w-40 h-40">
              <svg className="w-full h-full" viewBox="0 0 100 100">
                <circle
                  className="text-gray-700"
                  strokeWidth="10"
                  stroke="currentColor"
                  fill="transparent"
                  r="45"
                  cx="50"
                  cy="50"
                />
                <circle
                  className="text-blue-600"
                  strokeWidth="10"
                  strokeDasharray={`${2 * Math.PI * 45}`}
                  strokeDashoffset={`${(2 * Math.PI * 45) * (1 - progress / 100)}`}
                  strokeLinecap="round"
                  stroke="currentColor"
                  fill="transparent"
                  r="45"
                  cx="50"
                  cy="50"
                  transform="rotate(-90 50 50)"
                />
              </svg>
              <span className="absolute inset-0 flex items-center justify-center text-3xl font-bold">
                {progress}%
              </span>
            </div>
          </div>
        )}

        {step === "result" && (
          <div className="flex flex-col items-center justify-center w-full">
            <div className="flex gap-4 mb-8">
              <button
                onClick={handleDownload}
                className="rounded-full bg-blue-600 px-8 py-3 font-bold text-white hover:bg-blue-700 transition-transform duration-300 ease-in-out transform hover:scale-105"
              >
                Download Image
              </button>
              <button
                onClick={handleRestart}
                className="rounded-full bg-gray-600 px-8 py-3 font-bold text-white hover:bg-gray-700 transition-transform duration-300 ease-in-out transform hover:scale-105"
              >
                Restart
              </button>
            </div>
          </div>
        )}

        <canvas ref={canvasRef} className={`w-full rounded-lg bg-gray-800 my-8 ${step === 'result' ? '' : 'hidden'}`}></canvas>
        <video ref={videoRef} className="hidden" />
      </div>
    </main>
  );
}
