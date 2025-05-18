## Интеграция с Qdrant

В этом разделе описаны способы прямой интеграции Mem0 с векторной базой данных Qdrant, которая используется для хранения и поиска векторных эмбеддингов.

### Обзор архитектуры

Mem0 использует Qdrant как основное хранилище для векторных эмбеддингов, которые создаются на основе текстового содержимого воспоминаний. Архитектура интеграции выглядит следующим образом:

1. **Mem0** - основной сервис, который предоставляет API для работы с воспоминаниями
2. **PostgreSQL** - хранит метаданные и текстовое содержимое воспоминаний
3. **Qdrant** - хранит векторные эмбеддинги и обеспечивает семантический поиск
4. **OpenAI API** - используется для создания векторных эмбеддингов

### Настройка Qdrant для работы с Mem0

Qdrant уже настроен в вашем стеке Docker, но вот несколько важных параметров, которые следует учитывать:

1. **Коллекции**: Mem0 создает коллекцию `memories` в Qdrant для хранения эмбеддингов
2. **Размерность векторов**: По умолчанию используется размерность 1536 (для модели `text-embedding-ada-002` от OpenAI)
3. **Метрика расстояния**: Используется косинусное расстояние (cosine)

### Прямое взаимодействие с Qdrant API

Если вам необходимо напрямую взаимодействовать с Qdrant API для расширенных операций, вот основные эндпоинты:

#### 1. Проверка состояния коллекции

```bash
curl -X GET "http://qdrant:6333/collections/memories" \
  -H "Content-Type: application/json"
```

#### 2. Поиск по векторам

Если у вас есть векторное представление запроса, вы можете выполнить поиск напрямую через Qdrant:

```bash
curl -X POST "http://qdrant:6333/collections/memories/points/search" \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, ...], 
    "limit": 10,
    "with_payload": true
  }'
```

#### 3. Получение точки по ID

```bash
curl -X GET "http://qdrant:6333/collections/memories/points/mem_12345" \
  -H "Content-Type: application/json"
```

### Примеры кода для интеграции с Qdrant

Ниже представлены примеры кода для прямого взаимодействия с Qdrant из ваших приложений.

#### 1. Инициализация клиента Qdrant в Node.js

```javascript
// Установите пакет: npm install @qdrant/js-client-rest
const { QdrantClient } = require('@qdrant/js-client-rest');

// Инициализация клиента
const qdrantClient = new QdrantClient({ 
  url: 'http://qdrant:6333',
  apiKey: process.env.QDRANT_API_KEY // Если настроена аутентификация
});

// Проверка соединения
async function checkConnection() {
  try {
    const collections = await qdrantClient.getCollections();
    console.log('Доступные коллекции:', collections);
    return true;
  } catch (error) {
    console.error('Ошибка подключения к Qdrant:', error);
    return false;
  }
}
```

#### 2. Поиск похожих воспоминаний по вектору

```javascript
// Функция для поиска похожих воспоминаний по вектору
async function searchSimilarMemories(vector, limit = 5) {
  try {
    const searchResult = await qdrantClient.search('memories', {
      vector: vector,
      limit: limit,
      with_payload: true,
      with_vectors: false
    });
    
    console.log('Найдено похожих воспоминаний:', searchResult.length);
    return searchResult;
  } catch (error) {
    console.error('Ошибка при поиске в Qdrant:', error);
    return [];
  }
}

// Пример использования
// Предположим, у нас есть вектор из OpenAI API
const vector = [0.1, 0.2, ...]; // 1536 значений
const similarMemories = await searchSimilarMemories(vector);
```

#### 3. Создание эмбеддинга с помощью OpenAI и поиск в Qdrant

```javascript
// Установите пакет: npm install openai
const { OpenAI } = require('openai');

// Инициализация клиента OpenAI
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Функция для создания эмбеддинга текста
async function createEmbedding(text) {
  try {
    const response = await openai.embeddings.create({
      model: "text-embedding-ada-002",
      input: text
    });
    
    return response.data[0].embedding;
  } catch (error) {
    console.error('Ошибка при создании эмбеддинга:', error);
    throw error;
  }
}

// Функция для поиска похожих воспоминаний по тексту
async function searchSimilarMemoriesByText(text, limit = 5) {
  try {
    // Создание эмбеддинга для текста
    const vector = await createEmbedding(text);
    
    // Поиск похожих воспоминаний
    return await searchSimilarMemories(vector, limit);
  } catch (error) {
    console.error('Ошибка при поиске похожих воспоминаний:', error);
    return [];
  }
}

// Пример использования
const query = "Какие предпочтения у пользователя?";
const similarMemories = await searchSimilarMemoriesByText(query);
```

#### 4. Добавление новой точки в Qdrant

```javascript
// Функция для добавления новой точки в Qdrant
async function addPointToQdrant(id, vector, payload) {
  try {
    await qdrantClient.upsert('memories', {
      points: [
        {
          id: id,
          vector: vector,
          payload: payload
        }
      ]
    });
    
    console.log('Точка успешно добавлена в Qdrant');
    return true;
  } catch (error) {
    console.error('Ошибка при добавлении точки в Qdrant:', error);
    return false;
  }
}

// Пример использования
const memoryId = 'mem_' + Date.now();
const memoryText = "Пользователь предпочитает получать уведомления по email";
const vector = await createEmbedding(memoryText);
const payload = {
  content: memoryText,
  type: "preference",
  user_id: "user123",
  created_at: new Date().toISOString()
};

await addPointToQdrant(memoryId, vector, payload);
```

#### 5. Удаление точки из Qdrant

```javascript
// Функция для удаления точки из Qdrant
async function deletePointFromQdrant(id) {
  try {
    await qdrantClient.delete('memories', {
      points: [id]
    });
    
    console.log('Точка успешно удалена из Qdrant');
    return true;
  } catch (error) {
    console.error('Ошибка при удалении точки из Qdrant:', error);
    return false;
  }
}

// Пример использования
await deletePointFromQdrant('mem_12345');
```

### Расширенные возможности Qdrant

Qdrant предоставляет множество дополнительных возможностей, которые могут быть полезны при работе с Mem0:

#### 1. Фильтрация по метаданным

Вы можете использовать фильтрацию по метаданным для более точного поиска:

```javascript
// Поиск с фильтрацией по типу воспоминания и пользователю
async function searchWithFilters(vector, userId, type, limit = 5) {
  try {
    const searchResult = await qdrantClient.search('memories', {
      vector: vector,
      limit: limit,
      filter: {
        must: [
          {
            key: 'user_id',
            match: {
              value: userId
            }
          },
          {
            key: 'type',
            match: {
              value: type
            }
          }
        ]
      },
      with_payload: true
    });
    
    return searchResult;
  } catch (error) {
    console.error('Ошибка при поиске с фильтрами:', error);
    return [];
  }
}

// Пример использования
const vector = await createEmbedding("Какие предпочтения у пользователя?");
const preferences = await searchWithFilters(vector, "user123", "preference");
```

#### 2. Групповые операции

Вы можете выполнять групповые операции для повышения производительности:

```javascript
// Групповое добавление точек
async function batchAddPoints(points) {
  try {
    await qdrantClient.upsert('memories', {
      points: points
    });
    
    console.log(`Успешно добавлено ${points.length} точек`);
    return true;
  } catch (error) {
    console.error('Ошибка при групповом добавлении точек:', error);
    return false;
  }
}

// Пример использования
const memories = [
  {
    id: 'mem_1',
    vector: [...], // Вектор 1
    payload: { content: "Воспоминание 1", user_id: "user123", type: "fact" }
  },
  {
    id: 'mem_2',
    vector: [...], // Вектор 2
    payload: { content: "Воспоминание 2", user_id: "user123", type: "preference" }
  }
];

await batchAddPoints(memories);
```

#### 3. Рекомендательные системы

Qdrant можно использовать для создания рекомендательных систем на основе воспоминаний:

```javascript
// Функция для получения рекомендаций на основе предпочтений пользователя
async function getRecommendations(userId, limit = 5) {
  try {
    // Получение всех предпочтений пользователя
    const userPreferences = await qdrantClient.search('memories', {
      vector: [], // Пустой вектор, так как используем только фильтр
      limit: 100,
      filter: {
        must: [
          {
            key: 'user_id',
            match: {
              value: userId
            }
          },
          {
            key: 'type',
            match: {
              value: 'preference'
            }
          }
        ]
      },
      with_payload: true,
      with_vectors: true
    });
    
    // Если у пользователя нет предпочтений, возвращаем пустой массив
    if (userPreferences.length === 0) {
      return [];
    }
    
    // Вычисление среднего вектора предпочтений
    const avgVector = calculateAverageVector(userPreferences.map(p => p.vector));
    
    // Поиск похожих элементов на основе среднего вектора
    const recommendations = await qdrantClient.search('items', {
      vector: avgVector,
      limit: limit,
      with_payload: true
    });
    
    return recommendations;
  } catch (error) {
    console.error('Ошибка при получении рекомендаций:', error);
    return [];
  }
}

// Вспомогательная функция для вычисления среднего вектора
function calculateAverageVector(vectors) {
  const dimension = vectors[0].length;
  const avgVector = new Array(dimension).fill(0);
  
  for (const vector of vectors) {
    for (let i = 0; i < dimension; i++) {
      avgVector[i] += vector[i] / vectors.length;
    }
  }
  
  return avgVector;
}
```

### Мониторинг и обслуживание Qdrant

Для эффективной работы Mem0 важно правильно обслуживать Qdrant:

#### 1. Мониторинг состояния

```bash
# Проверка состояния Qdrant
curl -X GET "http://qdrant:6333/healthz"

# Получение статистики коллекции
curl -X GET "http://qdrant:6333/collections/memories"
```

#### 2. Оптимизация индексов

Периодически выполняйте оптимизацию индексов для повышения производительности:

```bash
curl -X POST "http://qdrant:6333/collections/memories/optimize" \
  -H "Content-Type: application/json"
```

#### 3. Резервное копирование

Регулярно создавайте резервные копии данных Qdrant:

```bash
# Создание снапшота
curl -X POST "http://qdrant:6333/collections/memories/snapshots" \
  -H "Content-Type: application/json"

# Получение списка снапшотов
curl -X GET "http://qdrant:6333/collections/memories/snapshots" \
  -H "Content-Type: application/json"

# Скачивание снапшота
curl -X GET "http://qdrant:6333/collections/memories/snapshots/{snapshot_name}" \
  -o memories_snapshot.snapshot
```

### Заключение

Прямая интеграция с Qdrant позволяет расширить возможности Mem0 и создавать более сложные сценарии использования, такие как:

- Персонализированные рекомендательные системы
- Расширенный семантический поиск с фильтрацией
- Кластеризация и анализ воспоминаний
- Создание графов знаний на основе векторных представлений

При интеграции с Qdrant важно учитывать, что векторные эмбеддинги создаются с помощью OpenAI API, поэтому необходимо иметь действующий ключ API и учитывать ограничения на количество запросов.
