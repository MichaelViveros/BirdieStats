# GET /api/rounds  
Returns all the golf rounds for a given user.

## Request
| Parameter | Type | Description |
| :----: | :----: | ---- |
| user | query  | Name of user, `""` will return rounds for all users |

## Response
```
Status: 200 OK
```

```json
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

# POST /api/input-rounds  
Creates a new round.

## Request
| Parameter | Type | Description |
| :----: | :----: | ---- |
| club | string | Name of club |
| courses | object[] | List of courses |
| date | string | Date of round in the format `YYYY-MM-DD` |
| players | string[] | List of players |

### course
| Parameter | Type | Description |
| :----: | :-------: | ---- |
| holeFlags | int[] | List of size 18 where `l[i] = 1` if there's a score for hole `i`, else `l[i] = 0` |
| name | string | Name of course
| numHoles | int | Number of holes played
| strokes | int[][] | List of size 18 where `l[i][j]` is player `i`'s strokes for hole `j`, `0` if hole wasn't played
| tees | string | Name of tees

### Example
```json
{
  "club": "Chedoke",
  "courses": [
    {
      "holeFlags": [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      "name": "Martin",
      "numHoles": 9,
      "strokes": [
        [4, 3, 7, 5, 5, 6, 4, 3, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [8, 5, 7, 3, 6, 4, 7, 4, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      ],
      "tees": "White"
    }
  ],
  "date": "2020-11-29",
  "players":[
    "Michael Viveros",
    "Roman Viveros"
  ]
}
```

## Response
```
Status: 200 OK
```

```json
{
  "success": true
}
```

```
Status: 200 OK
```

```json
{
  "err": "error: ... error message ..."
}
