import { Text as RNText, View as RNView, type TextProps, type ViewProps } from 'react-native';

export function Text(props: TextProps) {
  return <RNText {...props} />;
}

export function View(props: ViewProps) {
  return <RNView {...props} />;
}