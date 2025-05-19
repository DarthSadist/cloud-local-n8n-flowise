/**
 * Хелпер для работы с архивами и файлами в n8n
 * Упрощает создание, чтение и распаковку ZIP-архивов
 */

const JSZip = require('jszip');
const archiver = require('archiver');
const unzipper = require('unzipper');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { Readable } = require('stream');

class ArchiveHelper {
  /**
   * Создает экземпляр хелпера для работы с архивами
   */
  constructor() {
    // Создаем временную директорию для работы с файлами
    this.tempDir = path.join(os.tmpdir(), 'n8n-archive-helper');
    if (!fs.existsSync(this.tempDir)) {
      fs.mkdirSync(this.tempDir, { recursive: true });
    }
  }

  /**
   * Создание ZIP-архива из файлов
   * @param {Array<Object>} files - Массив объектов с файлами
   * @param {string} files[].name - Имя файла в архиве
   * @param {Buffer|string} files[].content - Содержимое файла (буфер или строка)
   * @returns {Promise<Buffer>} - Буфер с созданным ZIP-архивом
   */
  async createZip(files) {
    try {
      const zip = new JSZip();
      
      // Добавляем файлы в архив
      for (const file of files) {
        const content = typeof file.content === 'string' ? file.content : file.content;
        zip.file(file.name, content);
      }
      
      // Генерируем ZIP-архив
      return await zip.generateAsync({ type: 'nodebuffer' });
    } catch (error) {
      console.error('Error creating ZIP archive:', error);
      throw error;
    }
  }

  /**
   * Чтение содержимого ZIP-архива
   * @param {Buffer|string} input - Буфер с ZIP-архивом или путь к файлу
   * @param {Object} options - Параметры чтения
   * @param {boolean} options.binary - Возвращать содержимое файлов как буферы (true) или как строки (false)
   * @returns {Promise<Object>} - Объект с содержимым архива
   */
  async readZip(input, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      const zip = new JSZip();
      
      // Загружаем ZIP-архив
      const zipContent = await zip.loadAsync(buffer);
      const result = {};
      
      // Извлекаем содержимое файлов
      for (const [filename, file] of Object.entries(zipContent.files)) {
        if (!file.dir) {
          const content = await file.async(options.binary ? 'nodebuffer' : 'string');
          result[filename] = content;
        }
      }
      
      return result;
    } catch (error) {
      console.error('Error reading ZIP archive:', error);
      throw error;
    }
  }

  /**
   * Распаковка ZIP-архива во временную директорию
   * @param {Buffer|string} input - Буфер с ZIP-архивом или путь к файлу
   * @returns {Promise<string>} - Путь к директории с распакованными файлами
   */
  async extractZip(input) {
    try {
      const buffer = this._getBuffer(input);
      const extractDir = path.join(this.tempDir, 'extract_' + Date.now());
      
      if (!fs.existsSync(extractDir)) {
        fs.mkdirSync(extractDir, { recursive: true });
      }
      
      // Создаем поток из буфера
      const stream = Readable.from(buffer);
      
      // Распаковываем архив
      await new Promise((resolve, reject) => {
        stream
          .pipe(unzipper.Extract({ path: extractDir }))
          .on('close', () => resolve())
          .on('error', err => reject(err));
      });
      
      return extractDir;
    } catch (error) {
      console.error('Error extracting ZIP archive:', error);
      throw error;
    }
  }

  /**
   * Создание архива с использованием библиотеки archiver (поддерживает ZIP, TAR, и др.)
   * @param {Array<Object>} files - Массив объектов с файлами
   * @param {string} files[].name - Имя файла в архиве
   * @param {Buffer|string} files[].content - Содержимое файла (буфер или строка)
   * @param {Object} options - Параметры архива
   * @param {string} options.format - Формат архива (zip, tar, и т.д.)
   * @param {Object} options.formatOptions - Дополнительные параметры формата
   * @returns {Promise<Buffer>} - Буфер с созданным архивом
   */
  async createArchive(files, options = {}) {
    try {
      const format = options.format || 'zip';
      const formatOptions = options.formatOptions || {};
      
      // Создаем архив
      const archive = archiver(format, formatOptions);
      const chunks = [];
      
      // Настраиваем обработку данных
      archive.on('data', chunk => chunks.push(chunk));
      
      // Добавляем файлы в архив
      for (const file of files) {
        const content = typeof file.content === 'string' ? Buffer.from(file.content) : file.content;
        archive.append(content, { name: file.name });
      }
      
      // Завершаем архив
      archive.finalize();
      
      // Ждем завершения архивации
      return new Promise((resolve, reject) => {
        archive.on('end', () => {
          resolve(Buffer.concat(chunks));
        });
        
        archive.on('error', err => {
          reject(err);
        });
      });
    } catch (error) {
      console.error('Error creating archive:', error);
      throw error;
    }
  }

  /**
   * Получает буфер из входных данных
   * @param {Buffer|string} input - Буфер с архивом или путь к файлу
   * @returns {Buffer} - Буфер с архивом
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

module.exports = ArchiveHelper;
