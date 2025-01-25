
# Image Annotation Tool for Neural Network Training

This is a macOS application for annotating images to prepare datasets for object recognition neural networks. The tool is designed to simplify the creation of datasets in the CreateML-compatible format, enabling you to train, test, and validate machine learning models.

---

## 🚀 Features

### Project Management
- **Create a New Project:** Start a new annotation project by selecting a folder and naming the project.
- **Open Existing Projects:** Easily resume work on saved projects.

### Image Import and Organization
- **Add Folders with Images:** Import multiple folders containing images for annotation.
- **Folder View:** Navigate through folders and switch between groups of images effortlessly.
- **Image Previews:** View thumbnails of all images in the selected folder with annotation counters.

### Annotation and Classification
- **Add Classes:** Define object classes by entering their names and assigning unique colors.
- **Annotate Objects:** Use the mouse to draw bounding boxes around objects in images.
- **Class Management:**
  - Rename classes using the context menu.
  - Delete classes if no longer needed.
  - Change class colors for easier distinction.
- **Adjust Annotations:** Resize and reposition bounding boxes with anchor points on the corners.

### Multi-Language Support
- **Languages Available:**
  - English
  - German
  - Russian
- Switch languages through the `Settings > Languages` menu.

### Advanced Tools
- **Export for CreateML:** Split annotated data into three folders for training, testing, and validation:
  - Default proportions: `70% training`, `15% testing`, `15% validation`.
  - Modify proportions through `Settings > Export Proportions`.
  - Export includes annotated images and JSON files compatible with CreateML.
- **Image Rotation:** Enable `Rotate Output Images` to augment data by generating rotated versions (90°, 180°, 270°).
- **Clear Annotations:** Use the `Remove Annotations from Image` button to reset annotations on a specific image.

### Hotkeys for Navigation
- **Q:** Navigate to the previous image.
- **W:** Navigate to the next image.

### Logging
- **Activity Log:** Monitor all actions in a log window for reference and debugging.

---

## 📂 Installation and Usage

### Requirements
- macOS with Xcode installed.

### Steps to Install
1. Clone this repository:
   ```bash
   git clone https://github.com/XMaster-Denis/XAnnotation.git
   ```
2. Open the project in Xcode.
3. Build and run the application.

---

## 🔄 Export Workflow

1. Annotate all required images and organize classes.
2. Adjust export proportions via `Settings > Export Proportions` if needed.
3. Click `Export for CreateML` to generate dataset folders for training, testing, and validation.
4. Use CreateML in Xcode to train your model with the exported dataset.

---

## 🌟 Highlights
- **Supports Complex Projects:** Annotate multiple object classes in a single image.
- **Highly Customizable:** Manage class names, colors, and annotations with ease.
- **Augmentation Ready:** Generate rotated images for enhanced neural network training.

---

## 🖼 Application Screenshot

![Application Screenshot](assets/screenshot.png)

---

## 🛠 Contributing
Contributions are welcome! Feel free to fork the repository, make changes, and submit a pull request.

---

## 📜 License
This project is licensed under the [MIT License](LICENSE).

---

## 📞 Contact
For any questions or suggestions, feel free to open an issue or contact me directly.
