# API

## GET /api/rounds  
Returns all the golf rounds for a given user.

#### Parameters
| Parameter | Type | Description |
| :----: |:----:| ---- | ---- |
| user | query  | Name of user<br>"" will return rounds for all users |

```javascript
{
  "user": "Michael Viveros"
}
```

#### Responses
| Code | Response | Type | Description |
| :----: |:----:| :----:| ---- |
| 200 | rounds | body  | List of rounds |

```javascript
{
  "rounds": [
    {
      "date": "Fri May 06 2016",
      "club": "Chedoke",
      "courses": [
        {
          "name": "Beddoe",
          "tees": "Red",
          "holes": [
            1,2
          ],
          "numHoles": 2,
          "yards": [
            282,343
          ],
          "totalYards": 625,
          "pars": [
            4,4
          ],
          "totalPar": 8,
          "scores": [
            {
              "totalStrokes": 9,
              "strokes": [
                5,4
              ],
              "player": "test 1",
              "totalScore": 1
            }
          ]
        }
      ]
    }
  ]
}
```

## POST /api/input-rounds  
Adds a new round to the db

#### Parameters
| Parameter | Type | Description |
| :----: |:----:| ---- | ---- |
| date | body  | Date of round |
| club | body  | Club where round was played |
| courses | body  | List of courses, includes strokes for players |
| players | body  | List of players |

```javascript
{
  "date":"2016-05-17",
  "club":"Chedoke",
  "courses":[
    {
      "name":"Martin",
      "tees":"Red",
      "numHoles":3,
      "strokes":[
        ["4","6","3"]
      ],
      "holes":[
        1,2,3
      ]
    }
  ],
  "players":[
    "Michael Viveros"
  ]
}
```

#### Responses
| Code | Response | Type | Description |
| :----: |:----:| :----:| ---- |
| 200 | success | body  | Result of adding round to db |

```javascript
{
  "success":true
}
```