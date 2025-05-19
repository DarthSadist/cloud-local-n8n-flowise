/**
 * Хелпер для работы с изображениями в n8n
 * Упрощает обработку изображений с использованием библиотек sharp, gm и tesseract.js
 */

const sharp = require('sharp');
const gm = require('gm');
const tesseract = require('tesseract.js');
const imageSize = require('image-size');
const heicConvert = require('heic-convert');
const fs = require('fs');
const path = require('path');
const os = require('os');

class ImageHelper {
  /**
   * Создает экземпляр хелпера для работы с изображениями
   */
  constructor() {
    // Создаем временную директорию для работы с файлами
    this.tempDir = path.join(os.tmpdir(), 'n8n-image-helper');
    if (!fs.existsSync(this.tempDir)) {
      fs.mkdirSync(this.tempDir, { recursive: true });
    }
  }

  /**
   * Получение информации об изображении
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @returns {Promise<Object>} - Информация об изображении (ширина, высота, формат)
   */
  async getInfo(input) {
    try {
      const buffer = this._getBuffer(input);
      const info = imageSize(buffer);
      return {
        width: info.width,
        height: info.height,
        type: info.type,
        orientation: info.orientation
      };
    } catch (error) {
      console.error('Error getting image info:', error);
      throw error;
    }
  }

  /**
   * Изменение размера изображения
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @param {Object} options - Параметры изменения размера
   * @param {number} options.width - Ширина (опционально)
   * @param {number} options.height - Высота (опционально)
   * @param {boolean} options.fit - Тип подгонки (contain, cover, fill, inside, outside)
   * @param {string} options.format - Формат вывода (jpeg, png, webp, avif)
   * @returns {Promise<Buffer>} - Буфер с обработанным изображением
   */
  async resize(input, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      const sharpInstance = sharp(buffer);
      
      const resizeOptions = {};
      if (options.width) resizeOptions.width = options.width;
      if (options.height) resizeOptions.height = options.height;
      if (options.fit) resizeOptions.fit = options.fit;
      
      sharpInstance.resize(resizeOptions);
      
      if (options.format) {
        sharpInstance.toFormat(options.format, { quality: options.quality || 80 });
      }
      
      return await sharpInstance.toBuffer();
    } catch (error) {
      console.error('Error resizing image:', error);
      throw error;
    }
  }

  /**
   * Конвертация изображения из одного формата в другой
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @param {string} format - Формат вывода (jpeg, png, webp, avif)
   * @param {Object} options - Дополнительные параметры
   * @returns {Promise<Buffer>} - Буфер с конвертированным изображением
   */
  async convert(input, format, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      
      // Особая обработка для HEIC формата
      if (this._isHeic(buffer) && ['jpeg', 'png'].includes(format)) {
        return await this._convertHeic(buffer, format);
      }
      
      const sharpInstance = sharp(buffer);
      return await sharpInstance.toFormat(format, options).toBuffer();
    } catch (error) {
      console.error('Error converting image:', error);
      throw error;
    }
  }

  /**
   * Распознавание текста на изображении (OCR)
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @param {Object} options - Параметры распознавания
   * @param {string} options.lang - Язык распознавания (eng, rus, и т.д.)
   * @returns {Promise<string>} - Распознанный текст
   */
  async recognizeText(input, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      const lang = options.lang || 'eng';
      
      const { data } = await tesseract.recognize(buffer, {
        lang: lang
      });
      
      return data.text;
    } catch (error) {
      console.error('Error recognizing text:', error);
      throw error;
    }
  }

  /**
   * Добавление водяного знака на изображение
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @param {Object} options - Параметры водяного знака
   * @param {string} options.text - Текст водяного знака
   * @param {string} options.position - Позиция (center, top, bottom, left, right)
   * @param {number} options.opacity - Прозрачность (0-1)
   * @returns {Promise<Buffer>} - Буфер с изображением с водяным знаком
   */
  async addWatermark(input, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      const tempInput = path.join(this.tempDir, 'input.png');
      const tempOutput = path.join(this.tempDir, 'output.png');
      
      fs.writeFileSync(tempInput, buffer);
      
      const text = options.text || 'Watermark';
      const position = options.position || 'center';
      const opacity = options.opacity || 0.5;
      
      return new Promise((resolve, reject) => {
        gm(tempInput)
          .fill('white')
          .drawText(0, 0, text, position)
          .opacity(opacity)
          .write(tempOutput, (err) => {
            if (err) {
              reject(err);
              return;
            }
            
            const outputBuffer = fs.readFileSync(tempOutput);
            
            // Удаляем временные файлы
            try {
              fs.unlinkSync(tempInput);
              fs.unlinkSync(tempOutput);
            } catch (e) {
              console.error('Error cleaning up temp files:', e);
            }
            
            resolve(outputBuffer);
          });
      });
    } catch (error) {
      console.error('Error adding watermark:', error);
      throw error;
    }
  }

  /**
   * Обрезка изображения
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @param {Object} options - Параметры обрезки
   * @param {number} options.left - Отступ слева
   * @param {number} options.top - Отступ сверху
   * @param {number} options.width - Ширина
   * @param {number} options.height - Высота
   * @returns {Promise<Buffer>} - Буфер с обрезанным изображением
   */
  async crop(input, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      const sharpInstance = sharp(buffer);
      
      return await sharpInstance
        .extract({
          left: options.left || 0,
          top: options.top || 0,
          width: options.width || 100,
          height: options.height || 100
        })
        .toBuffer();
    } catch (error) {
      console.error('Error cropping image:', error);
      throw error;
    }
  }

  /**
   * Проверяет, является ли буфер HEIC изображением
   * @param {Buffer} buffer - Буфер с изображением
   * @returns {boolean} - true, если это HEIC
   * @private
   */
  _isHeic(buffer) {
    // Простая проверка сигнатуры HEIC файла
    if (buffer.length < 12) return false;
    
    const signature = buffer.toString('hex', 4, 12);
    return signature === '6674797068656963' || signature === '667479706d696631';
  }

  /**
   * Конвертирует HEIC в JPEG или PNG
   * @param {Buffer} buffer - Буфер с HEIC изображением
   * @param {string} format - Формат вывода (jpeg или png)
   * @returns {Promise<Buffer>} - Буфер с конвертированным изображением
   * @private
   */
  async _convertHeic(buffer, format) {
    try {
      const outputFormat = format === 'jpeg' ? 'JPEG' : 'PNG';
      const result = await heicConvert({
        buffer: buffer,
        format: outputFormat,
        quality: 0.8
      });
      
      return result;
    } catch (error) {
      console.error('Error converting HEIC:', error);
      throw error;
    }
  }

  /**
   * Получает буфер из входных данных
   * @param {Buffer|string} input - Буфер с изображением или путь к файлу
   * @returns {Buffer} - Буфер с изображением
   * @private
   */
  _getBuffer(input) {
    if (Buffer.isBuffer(input)) {
      return input;
    }
    
    if (typeof input === 'string') {
      return fs.readFileSync(input);
    }
    
    throw new Error('Input must be a buffer or a file path');
  }
}

module.exports = ImageHelper;
