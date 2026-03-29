import { Capacitor, registerPlugin } from "@capacitor/core";
import { FilePicker, type PickedFile } from "@capawesome/capacitor-file-picker";
import { Directory, Filesystem } from "@capacitor/filesystem";
import { Share } from "@capacitor/share";

type NativeShareOptions = {
  title: string;
  text: string;
  fileName?: string;
};

type PicsewMediaPlugin = {
  saveImageToPhotos(options: {
    dataUrl: string;
    fileName?: string;
  }): Promise<{ saved: boolean }>;
};

const PicsewMedia = registerPlugin<PicsewMediaPlugin>("PicsewMedia");

export type NativeVideoSource = "photos" | "files";

const DEFAULT_IMAGE_FILE_NAME = "long-screenshot.png";

export const isNativeIosApp = () =>
  Capacitor.isNativePlatform() && Capacitor.getPlatform() === "ios";

export const canUseNativeVideoImport = () => isNativeIosApp();

export const canUseNativeShare = () => isNativeIosApp();

export const canUseNativePhotoSave = () => isNativeIosApp();

export const isLikelyUserCancellation = (error: unknown) => {
  const message =
    error instanceof Error
      ? error.message
      : typeof error === "string"
        ? error
        : String(error);

  const normalized = message.toLowerCase();
  return (
    normalized.includes("cancel") ||
    normalized.includes("dismiss") ||
    normalized.includes("aborted")
  );
};

const stripDataUrlPrefix = (value: string) =>
  value.includes(",") ? value.slice(value.indexOf(",") + 1) : value;

const inferMimeType = (pickedFile: PickedFile) =>
  pickedFile.mimeType || "video/quicktime";

const inferLastModified = (pickedFile: PickedFile) =>
  pickedFile.modifiedAt ?? Date.now();

const fetchPickedBlob = async (pickedFile: PickedFile) => {
  if (pickedFile.blob) {
    return pickedFile.blob;
  }

  if (pickedFile.path) {
    const normalizedPath = Capacitor.convertFileSrc(pickedFile.path);
    const response = await fetch(normalizedPath);
    if (!response.ok) {
      throw new Error(`Failed to read selected file (${response.status}).`);
    }

    return response.blob();
  }

  if (pickedFile.data) {
    const binary = atob(stripDataUrlPrefix(pickedFile.data));
    const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
    return new Blob([bytes], {
      type: inferMimeType(pickedFile),
    });
  }

  throw new Error("Selected file did not include readable data.");
};

const toBrowserFile = async (pickedFile: PickedFile) => {
  const blob = await fetchPickedBlob(pickedFile);
  return new File([blob], pickedFile.name || "video.mov", {
    type: inferMimeType(pickedFile),
    lastModified: inferLastModified(pickedFile),
  });
};

const writeImageToTemporaryFile = async (
  imageDataUrl: string,
  fileName = DEFAULT_IMAGE_FILE_NAME,
) => {
  const path = `picsew/${Date.now()}-${fileName}`;
  await Filesystem.writeFile({
    path,
    directory: Directory.Temporary,
    data: stripDataUrlPrefix(imageDataUrl),
    recursive: true,
  });

  return Filesystem.getUri({
    path,
    directory: Directory.Temporary,
  });
};

export const pickNativeVideo = async (source: NativeVideoSource) => {
  const result =
    source === "photos"
      ? await FilePicker.pickVideos({ limit: 1 })
      : await FilePicker.pickFiles({
          limit: 1,
          types: ["video/*"],
        });

  const pickedFile = result.files[0];
  if (!pickedFile) {
    return null;
  }

  return toBrowserFile(pickedFile);
};

export const saveImageToPhotos = async (
  imageDataUrl: string,
  fileName = DEFAULT_IMAGE_FILE_NAME,
) => {
  if (!canUseNativePhotoSave()) {
    throw new Error("Native photo saving is only available on iOS.");
  }

  return PicsewMedia.saveImageToPhotos({
    dataUrl: imageDataUrl,
    fileName,
  });
};

export const shareGeneratedImage = async (
  imageDataUrl: string,
  options: NativeShareOptions,
) => {
  if (canUseNativeShare()) {
    const fileUri = await writeImageToTemporaryFile(
      imageDataUrl,
      options.fileName,
    );
    await Share.share({
      title: options.title,
      text: options.text,
      files: [fileUri.uri],
    });
    return;
  }

  if (!navigator.share) {
    throw new Error("Sharing is not supported in this browser.");
  }

  const response = await fetch(imageDataUrl);
  const blob = await response.blob();
  const file = new File([blob], options.fileName ?? DEFAULT_IMAGE_FILE_NAME, {
    type: "image/png",
  });

  if (navigator.canShare?.({ files: [file] })) {
    await navigator.share({
      files: [file],
      title: options.title,
      text: options.text,
    });
    return;
  }

  await navigator.share({
    title: options.title,
    text: options.text,
    url: imageDataUrl,
  });
};

export const supportsImageSharing = () =>
  canUseNativeShare() || typeof navigator.share !== "undefined";

export const getBase64Payload = stripDataUrlPrefix;
