import cvReadyPromise from "@techstark/opencv-js";
import cv from '@techstark/opencv-js';

type Cv = typeof cv;

export async function getOpenCV() {
  const cv = await cvReadyPromise;
  return cv as Cv;
}
