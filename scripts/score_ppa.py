"""Map verified EE470 PPA results to the instructor's published score interval."""

import argparse
import json
import math
from pathlib import Path
from statistics import mean, pstdev


# All metrics are costs. A lower raw value earns a higher component score.
WEIGHTS = {'execution_time_ps': 2, 'energy_J': 1, 'area_um2': 1}


def score(teams, minimum, maximum):
    if not (math.isfinite(minimum) and math.isfinite(maximum) and minimum <= maximum):
        raise ValueError('Supply a finite score interval with min <= max')
    output = {}
    verified = {}
    for row in teams:
        team = row['team_id']
        if not isinstance(team, str) or not team or team in output:
            raise ValueError('Team identifiers must be nonempty and unique')
        output[team] = {'ppa_score': None, 'weighted_cdf': None, 'metrics': None}
        if row.get('qualified') is not True:
            continue
        metrics = {key: float(row[key]) for key in WEIGHTS}
        if not all(math.isfinite(value) and value > 0 for value in metrics.values()):
            raise ValueError('Qualified PPA metrics must be finite and positive: ' + team)
        verified[team] = metrics
        output[team]['metrics'] = metrics
        output[team]['component_cdf'] = {}

    for key in WEIGHTS:
        values = [metrics[key] for metrics in verified.values()]
        if not values:
            break
        center, spread = mean(values), pstdev(values)
        for team, metrics in verified.items():
            z_score = (center - metrics[key]) / spread if spread else 0
            output[team]['component_cdf'][key] = (1 + math.erf(z_score / math.sqrt(2))) / 2

    for team in verified:
        cdf = output[team]['component_cdf']
        output[team]['weighted_cdf'] = sum(cdf[key] * weight for key, weight in WEIGHTS.items()) / sum(WEIGHTS.values())

    if verified:
        combined = [output[team]['weighted_cdf'] for team in verified]
        lower, upper = min(combined), max(combined)
        for team in verified:
            value = output[team]['weighted_cdf']
            fraction = (value - lower) / (upper - lower) if upper > lower else 0.5
            output[team]['ppa_score'] = minimum + fraction * (maximum - minimum)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('teams', type=Path, help='JSON list of team_id, qualified, execution_time_ps, energy_J, area_um2')
    parser.add_argument('--min-score', type=float, required=True)
    parser.add_argument('--max-score', type=float, required=True)
    args = parser.parse_args()
    try:
        teams = json.loads(args.teams.read_text(encoding='utf-8'))
        print(json.dumps(score(teams, args.min_score, args.max_score), indent=2))
    except (OSError, TypeError, ValueError, KeyError) as error:
        parser.error(str(error))


if __name__ == '__main__':
    main()
